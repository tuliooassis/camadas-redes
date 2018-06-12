<?php
    /* https://www.codeproject.com/Tips/418814/Socket-Programming-in-PHP */

    // set some variables
    $host = "localhost";
    $port = 15935;
    $portApp = 5678;
    // don't timeout!
    set_time_limit(0);
    $socket = socket_create(AF_INET, SOCK_STREAM, 0) or die("Could not create socket\n");
    $socketApp = socket_create(AF_INET, SOCK_STREAM, 0) or die("Could not create socket\n");

    // bind socket to port
    $result = socket_bind($socket, $host, $port) or die("Could not bind to socket\n");
    $resultApp = socket_bind($socketApp, $host, $portApp) or die("Could not bind to socket\n");

    // start listening for connections
    $result = socket_listen($socket, 3) or die("Could not set up socket listener\n");
    $resultApp = socket_listen($socketApp, 3) or die("Could not set up socket listener\n");

    // create sockets

    while (1) {
        // accept incoming connections
        // spawn another socket to handle communication
        $spawn = socket_accept($socket) or die("Could not accept incoming connection\n");

        // read client input
        $input = socket_read($spawn, 1024) or die("Could not read input\n");
        // clean up input string
        //$input = trim($input);
        echo "Client Message : ".$input;

        // responde pra camada fisica a resposta da camada de aplicação

        $output = "ola";
        socket_write($spawn, $output, strlen ($output)) or die("Could not write output\n");

        if ($input == "exit"){
            socket_shutdown($spawn, 2);
            socket_shutdown($socket, 2);
            socket_close($spawn);
            socket_close($socket);
            exit;
        }
    }
?>-