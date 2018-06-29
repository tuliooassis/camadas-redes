<?php
    // https://www.codeproject.com/Tips/418814/Socket-Programming-in-PHP
    $host    = "localhost";
    $portApp    = 53951;
    $portRede   = 34567;
    set_time_limit(0);

    $message = "Hello Server";
    echo "Message To server :".$message;
    // create socket
    $socket = socket_create(AF_INET, SOCK_STREAM, 0) or die("Could not create socket\n");
    
    // connect to server
    $result = socket_bind($socket, $host, $portApp) or die("Could not connect to server\n");  
    $result = socket_listen($socket, 3) or die("Could not set up socket listener\n");


     

    while (1){
        $spawn = socket_accept($socket) or die("Could not accept incoming connection\n");

	$socketRede = socket_create(AF_INET, SOCK_STREAM, 0) or die("Could not create socket\n");
    	$resultRede = socket_connect($socketRede, $host, $portRede) or die("Could not connect to server\n");

    // get server response
        $result = socket_read ($spawn, 1024) or die("Could not read server response\n");
        echo "Mensagem do cliente da aplicação : ".$result;

        
         
       // responde para a camada de rede o conteúdo retornado pela camada de aplicação
       socket_write($socketRede, $result, strlen($result)) or die("Could not send data to server\n");
        
       // echo "Executando a camada física";
      //  echo shell_exec('bash ../fisica/client.sh '.$result);

    }
    socket_close($socket);
?>
