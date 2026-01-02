#!/bin/bash
set -eux

# 1. Update and Install
dnf update -y
dnf install -y httpd php php-fpm php-mysqli

# 2. Start Services
systemctl enable --now php-fpm
systemctl enable --now httpd

# 3. CRITICAL: Remove default "It works!" page
rm -f /var/www/html/index.html

# 4. Create Static Health Check
echo "OK" > /var/www/html/health

# 5. Get Metadata
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)

# 6. Create Simple PHP Page
cat <<EOF > /var/www/html/index.php
<!DOCTYPE html>
<html>
<head>
    <title>Vanish App - LONDON</title>
    <style>
        body { font-family: sans-serif; padding: 20px; }
        .success { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
        hr { border: 0; border-top: 1px solid #ccc; margin: 20px 0; }
    </style>
</head>
<body>
    <h2>Vanish Global App - LONDON</h2>
    
    <p><strong>Region:</strong> $REGION</p>
    <p><strong>Availability Zone:</strong> $AZ</p>
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
    \$conn = new mysqli(\$host, \$user, \$pass, \$dbname);
    
    // Check Read/Write Status
    \$result = \$conn->query("SELECT @@global.read_only as is_read_only");
    \$row = \$result->fetch_assoc();
    \$is_read_only = \$row['is_read_only'];

    // 1. Green Checkmark & Success Message
    echo "<p class='success'>✅ Database Connection Successful</p>";

    // 2. Database Read/Write Status
    if (\$is_read_only == "1") {
        echo "<p><strong>DATABASE - READ</strong></p>";
    } else {
        echo "<p><strong>DATABASE - WRITE</strong></p>";
    }

    // 3. Database ID (Host)
    echo "<p>Database ID: " . \$host . "</p>";

    \$conn->close();

} catch (Exception \$e) {
    // Failure Message
    echo "<p class='fail'>❌ Database Connection Failed</p>";
    echo "<p>Error: " . \$e->getMessage() . "</p>";
}
?>
</body>
</html>
EOF

# 7. Permissions and Restart
chown -R apache:apache /var/www/html
chmod 644 /var/www/html/health /var/www/html/index.php
systemctl restart php-fpm httpd