#!/bin/bash
# 1. Update and install Apache + PHP + MySQL driver
yum update -y
yum install -y httpd php php-mysqlnd
systemctl start httpd
systemctl enable httpd

# 2. Get the IMDSv2 token for metadata
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# 3. Grab metadata for the display
AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(echo "$AZ" | sed 's/[a-z]$//')
LOCAL_IPV4=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)

# 4. Create the PHP landing page
# Note: In a real app, you'd pull DB_HOST from an environment variable or Secrets Manager.
# For now, this is a placeholder you can update with your Aurora Endpoint.
cat <<'EOF' > /var/www/html/index.php
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Vanish App - Connection Test</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding-top: 50px; background-color: #f4f4f4; }
        .card { background: white; padding: 20px; border-radius: 10px; display: inline-block; box-shadow: 0 4px 8px rgba(0,0,0,0.1); width: 80%; max-width: 600px; }
        .status { padding: 10px; border-radius: 5px; font-weight: bold; margin-top: 10px; }
        .success { background: #d4edda; color: #155724; }
        .failure { background: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Hello from <?php echo shell_exec('echo $REGION'); ?></h1>
        <p><b>Instance IP:</b> <?php echo $_SERVER['SERVER_ADDR']; ?></p>
        <p><b>Availability Zone:</b> <?php echo shell_exec('echo $AZ'); ?></p>

        <hr>

        <h3>Database Connection Status</h3>
        <?php
        // REPLACE THESE with your actual Terraform output values or environment variables
        $host = "REPLACE_WITH_YOUR_AURORA_ENDPOINT"; 
        $user = "admin";
        $pass = "CHECK_SECRETS_MANAGER"; // Since you used manage_master_user_password
        $db   = "vanish_db";

        $conn = new mysqli($host, $user, $pass, $db);

        if ($conn->connect_error) {
            echo "<div class='status failure'>❌ Connection Failed: " . $conn->connect_error . "</div>";
        } else {
            echo "<div class='status success'>✅ Successfully connected to Aurora!</div>";
            $conn->close();
        }
        ?>
        
        <br>
        <img src="https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExZmZrc3A0YnJqd3E0NjFtOHdka2IweTR0NGQxNGh6YXQzNmRrejQ3byZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7abA4a0QCXtSxGN2/giphy.gif" width="200">
    </div>
</body>
</html>
EOF

# Move the region/AZ into environment variables so PHP can see them
echo "export REGION=$REGION" >> /etc/sysconfig/httpd
echo "export AZ=$AZ" >> /etc/sysconfig/httpd
systemctl restart httpd