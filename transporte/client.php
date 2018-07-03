<?php
    // https://www.codeproject.com/Tips/418814/Socket-Programming-in-PHP
    $host    = "localhost";
    $portApp    = 53951; // porta da camada de aplicação
    $portRede   = 34567; // porta da camada de rede
    set_time_limit(0);

    // cria socket
    $socket = socket_create(AF_INET, SOCK_STREAM, 0) or die("Could not create socket\n");
    $result = socket_bind($socket, $host, $portApp) or die("Could not connect to server\n");
    $result = socket_listen($socket, 3) or die("Could not set up socket listener\n");

    while (1){
        // aceita a conexão
        echo "\nAceitando uma nova conexão";
        $spawn = socket_accept($socket) or die("Could not accept incoming connection\n");

        // cria e conecta com socket da camada de rede
        echo "\nConectando com a camada de rede";
	    $socketRede = socket_create(AF_INET, SOCK_STREAM, 0) or die("Could not create socket\n");
    	$resultRede = socket_connect($socketRede, $host, $portRede) or die("Could not connect to server\n");

        // lê a mensagem da camada de aplicação
        $result = socket_read ($spawn, 1024) or die("Could not read server response\n");
        echo "\nMensagem do cliente da aplicação: ".$result;

       // responde para a camada de rede o conteúdo retornado pela camada de aplicação
       socket_write($socketRede, $result, strlen($result)) or die("Could not send data to server\n");
       echo "\nConteúdo enviado para a camada de rede";
    }
    socket_close($socket);
?>
