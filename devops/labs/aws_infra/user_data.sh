#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y apache2 php libapache2-mod-php php-mysql mysql-client

cat > /var/www/html/index.php <<'PHP'
<?php
$db_host = '${db_host}';
$db_name = '${db_name}';
$db_user = '${db_user}';
$db_pass = '${db_password}';

$mysqli = @new mysqli($db_host, $db_user, $db_pass, $db_name, 3306);

if ($mysqli->connect_errno) {
    http_response_code(500);
    echo "<h1>Web server is running, but database connection failed</h1>";
    echo "<p>Error: " . htmlspecialchars($mysqli->connect_error) . "</p>";
    echo "<p>RDS may still be starting. Refresh in 2-3 minutes.</p>";
    exit;
}

$mysqli->query("CREATE TABLE IF NOT EXISTS visits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)");
$mysqli->query("INSERT INTO visits () VALUES ()");
$result = $mysqli->query("SELECT COUNT(*) AS total_visits FROM visits");
$row = $result ? $result->fetch_assoc() : ['total_visits' => 'unknown'];
?>
<!doctype html>
<html>
<head>
    <title>Terraform AWS Web + RDS Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f7f7f7; }
        .card { background: white; padding: 24px; border-radius: 10px; max-width: 760px; box-shadow: 0 2px 10px rgba(0,0,0,.08); }
        code { background: #eee; padding: 2px 6px; border-radius: 4px; }
        .ok { color: #0a7f2e; }
    </style>
</head>
<body>
    <div class="card">
        <h1 class="ok">Apache/PHP Web App is Running</h1>
        <p>EC2 web server successfully connected to private RDS MySQL.</p>
        <p><strong>Database:</strong> <code><?php echo htmlspecialchars($db_name); ?></code></p>
        <p><strong>RDS endpoint:</strong> <code><?php echo htmlspecialchars($db_host); ?></code></p>
        <p><strong>Total page visits stored in DB:</strong> <?php echo htmlspecialchars($row['total_visits']); ?></p>
    </div>
</body>
</html>
PHP

rm -f /var/www/html/index.html
chown -R www-data:www-data /var/www/html
systemctl enable apache2
systemctl restart apache2
