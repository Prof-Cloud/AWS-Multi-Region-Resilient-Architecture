#!/bin/bash
set -eux

# 1. Update and Install
dnf update -y
dnf install -y httpd php php-fpm php-mysqli

# 2. Start Services
systemctl enable --now php-fpm
systemctl enable --now httpd

# 3. CRITICAL FIX: Remove default Apache "It works!" page
rm -f /var/www/html/index.html

# 4. Create Static Health Check
echo "OK" > /var/www/html/health

# 5. Get Metadata for the UI (Region/AZ)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)

# 6. Create the App Page
cat <<EOF > /var/www/html/index.php
<!DOCTYPE html>
<html>
<head>
    <title>Vanish Global App</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding: 20px; background: #f4f4f4; }
        .box { background: white; border: 1px solid #ccc; padding: 20px; margin: 20px auto; max-width: 600px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .success { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
        .meta { color: #555; font-size: 0.9em; margin-top: 10px; }
    </style>
</head>
<body>
    <div class="box">
        <h1>GetVanish Global App</h1>
        <div class="meta">
            <p><strong>Region:</strong> $REGION &bull; <strong>Zone:</strong> $AZ</p>
            <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
        </div>
        <hr>
        <h3>Database Status</h3>
<?php
\$host = "${db_endpoint}";
\$user = "${db_user}";
\$pass = "${db_password}";
\$dbname = "${db_name}";

mysqli_report(MYSQLI_REPORT_STRICT | MYSQLI_REPORT_ERROR);
try {
    \$conn = new mysqli(\$host, \$user, \$pass, \$dbname);
    echo "<p class='success'>✅ Database Connection Successful!</p>";
    echo "<p>Connected to: <strong>" . \$host . "</strong></p>";
    \$conn->close();
} catch (Exception \$e) {
    echo "<p class='fail'>❌ Database Connection Failed</p>";
    echo "<p>Error: " . \$e->getMessage() . "</p>";
}
?>
    </div>
</body>
</html>
EOF

# 7. Permissions and Restart
chown -R apache:apache /var/www/html
chmod 644 /var/www/html/health /var/www/html/index.php
systemctl restart php-fpm httpd