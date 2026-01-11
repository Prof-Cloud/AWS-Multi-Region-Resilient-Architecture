#!/bin/bash
# Enable logging for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -eux

# 1. Install packages
dnf update -y
dnf install -y httpd php php-fpm php-mysqli mariadb105

# 2. Prepare Health Check File
mkdir -p /var/www/html
echo "OK" > /var/www/html/health

# 3. Configure Apache for PHP-FPM
cat <<EOF > /etc/httpd/conf.d/php-fpm.conf
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost"
</FilesMatch>

<Location "/health">
    SetHandler none
    Require all granted
</Location>
EOF

# 4. Get Metadata (IMDSv2) - Fixed Token & Region Fetch
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

# 5. Create App Page
cat <<EOF > /var/www/html/index.php
<!DOCTYPE html>
<html>
<head><title>Vanish App - $REGION</title></head>
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

mysqli_report(MYSQLI_REPORT_STRICT | MYSQLI_REPORT_ERROR);

try {
    \$conn = mysqli_init();
    \$conn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 5);
    \$conn->real_connect(\$host, \$user, \$pass, \$dbname);

    \$result = \$conn->query("SELECT @@global.read_only as is_read_only");
    \$row = \$result->fetch_assoc();
    echo "<p style='color:green'>✅ Database Connected</p>";
    echo (\$row['is_read_only'] == "1") ? "<p>Mode: <b>READ-ONLY (Secondary)</b></p>" : "<p>Mode: <b>READ-WRITE (Primary)</b></p>";
    \$conn->close();
} catch (Exception \$e) {
    echo "<p style='color:red'>❌ Connection Failed: " . \$e->getMessage() . "</p>";
}
?>
</body>
</html>
EOF

# 6. Set permissions and Start Services
chown -R apache:apache /var/www/html
systemctl enable php-fpm
systemctl start php-fpm
systemctl enable httpd
systemctl start httpd

# 7. SIGNAL: Complete the Lifecycle Hook
# Note: Using escaped variable for instance_id and region to ensure it uses the runtime values
aws autoscaling complete-lifecycle-action \
    --lifecycle-hook-name await-userdata \
    --auto-scaling-group-name ${asg_name} \
    --lifecycle-action-result CONTINUE \
    --instance-id \$INSTANCE_ID \
    --region \$REGION