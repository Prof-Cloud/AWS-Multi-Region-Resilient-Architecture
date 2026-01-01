#!/bin/bash
set -eux

# 1. Update and Install Web Stack
dnf update -y
dnf install -y httpd php php-fpm php-mysqli

# 2. Start Services
systemctl enable --now php-fpm
systemctl enable --now httpd

# 3. Clean up default files
rm -f /var/www/html/index.html

# 4. Create Health Check for the ALB
echo "OK" > /var/www/html/health

# 5. Fetch Metadata (IMDSv1)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# 6. Create the PHP Application Page
cat <<EOF > /var/www/html/index.php
<!DOCTYPE html>
<html>
<head>
    <title>Vanish Global App - LONDON</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; text-align: center; padding: 20px; background: #f0f2f5; }
        .box { background: white; border: 1px solid #d1d9e0; padding: 40px; margin: 50px auto; max-width: 650px; border-radius: 12px; box-shadow: 0 12px 30px rgba(0,0,0,0.15); }
        .success { color: #2ecc71; font-weight: bold; font-size: 1.2em; }
        .fail { color: #e74c3c; font-weight: bold; }
        .meta { color: #666; font-size: 0.9em; margin-top: 25px; border-top: 1px solid #eee; padding-top: 20px; line-height: 1.6; }
        .badge { display: inline-block; padding: 8px 16px; border-radius: 25px; font-weight: bold; font-size: 0.85em; text-transform: uppercase; margin-bottom: 20px; }
        .region-badge { background: #34495e; color: white; }
        .db-status-writer { background: #2ecc71; color: white; padding: 4px 10px; border-radius: 5px; }
        .db-status-reader { background: #f39c12; color: white; padding: 4px 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="box">
        <h1>GetVanish Global App</h1>
        <div class="badge region-badge">Secondary Region: London ($REGION)</div>
        
        <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">

        <h3>Database Connectivity Status</h3>
<?php
\$host = "${db_endpoint}";
\$user = "${db_user}";
\$pass = "${db_password}";
\$dbname = "${db_name}";

mysqli_report(MYSQLI_REPORT_STRICT | MYSQLI_REPORT_ERROR);
try {
    \$conn = new mysqli(\$host, \$user, \$pass, \$dbname);
    
    // Check if the DB is Read-Only
    \$result = \$conn->query("SELECT @@global.read_only as is_read_only");
    \$row = \$result->fetch_assoc();
    \$is_read_only = \$row['is_read_only'];

    echo "<p class='success'>✅ Connected to Cluster</p>";
    
    if (\$is_read_only == "1") {
        echo "<p>Current State: <span class='db-status-reader'>[ BRACKET READ ONLY ]</span></p>";
        echo "<p style='font-size: 0.85em; color: #7f8c8d;'>Status: Waiting for promotion in failover event...</p>";
    } else {
        echo "<p>Current State: <span class='db-status-writer'>[ WRITE DATABASE ACTIVE ]</span></p>";
        echo "<p style='font-size: 0.85em; color: #27ae60;'>Status: Success! This region is now the Master Writer.</p>";
    }

    \$conn->close();
} catch (Exception \$e) {
    echo "<p class='fail'>❌ Database Connection Failed</p>";
    echo "<p style='font-size: 0.8em; color: #999;'>Error: " . \$e->getMessage() . "</p>";
}
?>
        <div class="meta">
            <p><strong>Zone:</strong> $AZ &bull; <strong>Instance:</strong> $INSTANCE_ID</p>
            <p style="font-size: 0.8em; color: #999;">Endpoint: <code>" . \$host . "</code></p>
        </div>
    </div>
</body>
</html>
EOF

# 7. Final Permissions and Service Refresh
chown -R apache:apache /var/www/html
chmod 644 /var/www/html/health /var/www/html/index.php
systemctl restart php-fpm httpd