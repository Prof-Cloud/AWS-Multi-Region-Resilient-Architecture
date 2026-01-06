#!/bin/bash
# Enable logging for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -ux 

# 1. Start Health Check Services
dnf install -y httpd php php-fpm php-mysqli
systemctl enable --now php-fpm
systemctl enable --now httpd

# 2. Create Static Health Check EARLY
echo "OK" > /var/www/html/health
chown apache:apache /var/www/html/health

# 3. Get Metadata (IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

# 4. Create the App Page
cat <<EOF > /var/www/html/index.php
<!DOCTYPE html>
<html>
<head>
    <title>Vanish App - LONDON</title>
    <style>
        body { font-family: sans-serif; padding: 20px; background-color: #f4f4f9; }
        .container { border: 1px solid #ddd; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .success { color: #2d8a2d; font-weight: bold; }
        .fail { color: #d93025; font-weight: bold; }
        .header { color: #232f3e; border-bottom: 2px solid #ff9900; padding-bottom: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h2 class="header">🇬🇧 Vanish Global App - LONDON</h2>
        <p><strong>Region:</strong> $REGION</p>
        <p><strong>AZ:</strong> $AZ</p>
        <p><strong>Instance:</strong> $INSTANCE_ID</p>
        <hr>
        <h3>Database Status</h3>
<?php
// PHP variables are escaped with \
\$host = "${db_endpoint}";
\$user = "${db_user}";
\$pass = "${db_password}";
\$dbname = "${db_name}";

try {
    \$conn = new mysqli(\$host, \$user, \$pass, \$dbname);
    \$result = \$conn->query("SELECT @@global.read_only as is_read_only");
    \$row = \$result->fetch_assoc();
    
    echo "<p class='success'>✅ Connected to Database</p>";
    if (\$row['is_read_only'] == "1") {
        echo "<p>Mode: <span style='background:#fff3cd;padding:2px 5px;'>READ-ONLY (Passive)</span></p>";
    } else {
        echo "<p>Mode: <span style='background:#d4edda;padding:2px 5px;'>READ/WRITE (Active)</span></p>";
    }
    \$conn->close();
} catch (Exception \$e) {
    echo "<p class='fail'>❌ Connection Failed</p>";
    echo "<p>Error: " . htmlspecialchars(\$e->getMessage()) . "</p>";
}
?>
    </div>
</body>
</html>
EOF

# 5. Finalize permissions
chown -R apache:apache /var/www/html
chmod 644 /var/www/html/index.php /var/www/html/health
systemctl restart httpd
