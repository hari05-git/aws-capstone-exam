<?php
$server_ip = $_SERVER['SERVER_ADDR'] ?? gethostbyname(gethostname());
?>
<!DOCTYPE html>
<html>
<head>
  <title>StreamLine Directory</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #0f172a;
      color: #e5e7eb;
      margin: 40px;
    }
    .card {
      border: 1px solid #334155;
      padding: 20px;
      border-radius: 10px;
      max-width: 500px;
      background-color: #020617;
    }
    h1 {
      color: #38bdf8;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>Welcome to StreamLine - v2 [New Feature]</h1>
    <p><strong>Server IP Address:</strong> <?php echo $server_ip; ?></p>
  </div>
</body>
</html>
