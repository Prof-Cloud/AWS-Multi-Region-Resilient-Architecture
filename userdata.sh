#!/bin/bash
# Enable logging for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -eux

# 1. Install packages
dnf update -y
dnf install -y httpd php php-fpm php-mysqli

# 2. Prepare Files
rm -f /var/www/html/index.html
echo "OK" > /var/www/html/health

# --- FIX START: Configure Apache to talk to PHP-FPM ---
# This ensures Apache sends .php files to the PHP-FPM service
cat <<EOF > /etc/httpd/conf.d/php-fpm.conf
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost"
</FilesMatch>

<Location "/health">
    SetHandler none
    Require all granted
</Location>
EOF
# --- FIX END ---

# 3. Get Metadata (IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

## 4. Create App Page
cat <<EOF > /var/www/html/index.php
<!DOCTYPE html>
<html>
<body>
    <h2>Vanish Global App</h2>
    <p><strong>Region:</strong> $REGION</p>
    <p><strong>AZ:</strong> $AZ</p>
    <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
    <hr>
    <h3>Database Status</h3>
<?php
\$host = "${db_endpoint}";
\$user = "${db_user}";
\$pass = "${db_password}";
\$dbname = "${db_name}";

try {
    \$conn = new mysqli(\$host, \$user, \$pass, \$dbname);
    \$result = \$conn->query("SELECT @@global.read_only as is_read_only");
    \$row = \$result->fetch_assoc();
    echo "<p style='color:green'>✅ Database Connected</p>";
    echo (\$row['is_read_only'] == "1") ? "<p>Mode: <b>READ-ONLY</b></p>" : "<p>Mode: <b>READ-WRITE</b></p>";
    \$conn->close();
} catch (Exception \$e) {
    echo "<p style='color:red'>❌ Connection Failed</p>";
}
?>
</body>
</html>
EOF

# 5. Set permissions and Start
chown -R apache:apache /var/www/html
# Start PHP-FPM first, then Apache
systemctl enable php-fpm
systemctl start php-fpm
systemctl enable httpd
systemctl start httpd

# 6. SIGNAL: Complete the Lifecycle Hook
# This moves the instance from Pending:Wait to InService
aws autoscaling complete-lifecycle-action \
    --lifecycle-hook-name await-userdata \
    --auto-scaling-group-name ${asg_name} \
    --lifecycle-action-result CONTINUE \
    --instance-id $INSTANCE_ID \
    --region $REGION