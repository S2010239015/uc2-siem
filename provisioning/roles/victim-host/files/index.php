<?php
require 'db.php';
$c = new mysqli($db_host, $db_user, $db_pass, $db_name);
if ($c->connect_errno) {
    http_response_code(500);
    echo "DB-Fehler";
    exit;
}
echo "<h1>Kundenportal</h1><ul>";
$res = $c->query("SELECT id, name FROM kunden ORDER BY id");
while ($row = $res->fetch_assoc()) {
    echo "<li>" . htmlspecialchars($row['name']) . "</li>";
}
echo "</ul>";
