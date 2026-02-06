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
      background-color: #ffffff;
      margin: 40px;
    }
    .card {
      border: 1px solid #ccc;
      padding: 20px;
      border-radius: 10px;
      max-width: 500px;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>Welcome to Streamline - v1</h1>
    <p><strong>Server IP Address:</strong> <?php echo $server_ip; ?></p>
  </div>
</body>
</html>
