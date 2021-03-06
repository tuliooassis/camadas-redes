<?php
    /* https://www.codeproject.com/Tips/418814/Socket-Programming-in-PHP */

    $host = "localhost";
    $port = 15935; // porta da camada de rede
    $portApp = 5678; // porta da camada de aplicação

    set_time_limit(0);

    // cria socket com a camada de rede
    $socket = socket_create(AF_INET, SOCK_STREAM, 0) or die("Could not create socket\n");
    $result = socket_bind($socket, $host, $port) or die("Could not bind to socket\n");
    $result = socket_listen($socket, 3) or die("Could not set up socket listener\n");


    while (1) {
        echo "\nNova conexão aceita";
        $spawn = socket_accept($socket) or die("Could not accept incoming connection\n");

        echo "\nCria e conecta com socket da camada de aplicação";
        $socketApp = socket_create(AF_INET, SOCK_STREAM, 0) or die("Could not create socket\n");
        $resultApp = socket_connect($socketApp, $host, $portApp) or die("Could not connect to server\n");

        // lê mensagem da camada de rede
        $input = socket_read($spawn, 1024) or die("Could not read input\n");
        $input = trim($input);
        echo "\nMensagem da camada de rede: ".$input;

        // envia para a camada de aplicação a mensagem da camada física
        socket_write($socketApp, $input, strlen($input)) or die("Could not send data to server\n");

        echo "\nAguardando resposta da camada de aplicação";
        // lê a resposta da camada de aplicação
        $resposta = socket_read($socketApp, 2048) or die("Could not read input\n");
        echo "\nResposta da camada de aplicação: ".$resposta;

        // responde para a camada de rede o conteúdo retornado pela camada de aplicação
        socket_write($spawn, $resposta, strlen($resposta)) or die("Could not send data to server\n");
        echo "\nConteúdo da camada de aplicação enviado para a camada de rede";
        
        socket_shutdown($socketApp);
        socket_close($socketApp);
        if ($input == "exit"){
            socket_shutdown($spawn, 2);
            socket_shutdown($socket, 2);
            socket_close($spawn);
            socket_close($socket);
            exit;
        }
    }
?>-
