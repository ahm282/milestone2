<?php

ini_set('display_errors', 1);
error_reporting(E_ALL);

// Replace these values with your actual database credentials
$host = 'postgres-service';
$dbname = 'milestone';
$user = 'kube';
$password = 'kube';
$port = 5432;

// Establish a connection
$conn = pg_connect("host=$host dbname=$dbname user=$user password=$password port=");

if (!$conn) {
    echo "Unable to connect to the database.";
    exit;
}

// Execute a query
$result = pg_query($conn, "select * from fullname");

if (!$result) {
    echo "Error in query execution.";
    exit;
}

// Fetch and display the results
while ($row = pg_fetch_assoc($result)) {
    $name_db = $row['name'];
}

// Close the connection
pg_close($conn);
?>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Milestone 2</title>
    </head>
    <body>
        <h1><span id="user">Loading....</span> has reached milestone 2!</h2>
        <h2><span id="hostname">Loading....</span> API has responded to this request!</h2>
        <h3><?php echo $name_db; ?> has reached milestone 2! DATABASE WORKS!!!</h3>
        <script>
            // fetch user from API
            fetch("http://api.pretzel218.messwithdns.com/name")
                .then((res) => res.json())
                .then((data) => {
                // get user name
                const user = data.name;
                const hostname = data.hostname;
                // display user name
                setTimeout(() => {
                    document.getElementById("user").innerText = user;
                    document.getElementById("hostname").innerText = hostname;
                }, 600);
                });
        </script> 
    </body>
</html>