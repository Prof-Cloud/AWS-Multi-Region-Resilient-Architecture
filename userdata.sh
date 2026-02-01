#!/bin/bash
###############################################################################
# Vanish Global App - EC2 User Data Script (PRIMARY)
###############################################################################

# Enable logging
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -eux


###############################################################################
# 1. Install packages
###############################################################################

dnf update -y
dnf install -y httpd php php-fpm php-mysqli


###############################################################################
# 2. Prepare web root
###############################################################################

rm -f /var/www/html/index.html
echo "OK" > /var/www/html/health


###############################################################################
# 3. Apache ↔ PHP-FPM configuration
###############################################################################

cat <<'EOF' > /etc/httpd/conf.d/php-fpm.conf
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost"
</FilesMatch>

<Location "/health">
    SetHandler none
    Require all granted
</Location>
EOF


###############################################################################
# 4. PHP-FPM socket configuration
###############################################################################

# Ensure the directory exists so Apache doesn't get a 502 Error
mkdir -p /run/php-fpm
chown apache:apache /run/php-fpm

sed -i 's|^listen = .*|listen = /run/php-fpm/www.sock|' /etc/php-fpm.d/www.conf
sed -i 's|^;listen.owner = .*|listen.owner = apache|' /etc/php-fpm.d/www.conf
sed -i 's|^;listen.group = .*|listen.group = apache|' /etc/php-fpm.d/www.conf
sed -i 's|^;listen.mode = .*|listen.mode = 0660|' /etc/php-fpm.d/www.conf


###############################################################################
# 5. EC2 metadata (IMDSv2)
###############################################################################

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)


###############################################################################
# 6. Application page
###############################################################################

cat <<EOF > /var/www/html/index.php
<!DOCTYPE html>
<html>
<head>
    <title>Vanish Global App</title>
</head>
<body>

<h2>Vanish Global App</h2>

<p><strong>Region:</strong> $REGION</p>
<p><strong>AZ:</strong> $AZ</p>
<p><strong>Instance ID:</strong> $INSTANCE_ID</p>

<hr>

<h3>Database Status</h3>

<?php
\$host   = "${db_endpoint}";
\$user   = "${db_user}";
\$pass   = "${db_password}";
\$dbname = "${db_name}";

mysqli_report(MYSQLI_REPORT_STRICT | MYSQLI_REPORT_ERROR);

try {
    \$conn = mysqli_init();
    \$conn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 5);
    \$conn->real_connect(\$host, \$user, \$pass, \$dbname);

    // Get Server ID (Node Name)
    \$result = \$conn->query("SELECT @@aurora_server_id AS server_id");
    \$row = \$result->fetch_assoc();

    echo "<p style='color:green'>✅ Database Connected</p>";
    echo "<p>Connected to Node: <b>" . \$row['server_id'] . "</b></p>";

    \$conn->close();

} catch (Exception \$e) {
    echo "<p style='color:red'>❌ Connection Failed: " . \$e->getMessage() . "</p>";
}
?>

</body>
</html>
EOF


###############################################################################
# 7. Start services
###############################################################################

chown -R apache:apache /var/www/html

systemctl enable php-fpm
systemctl start php-fpm

sleep 2

systemctl enable httpd
systemctl start httpd


###############################################################################
# 8. Signal ASG lifecycle hook
###############################################################################

aws autoscaling complete-lifecycle-action \
  --lifecycle-hook-name await-userdata \
  --auto-scaling-group-name ${asg_name} \
  --lifecycle-action-result CONTINUE \
  --instance-id $INSTANCE_ID \
  --region $REGION