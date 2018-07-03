var spawn = require('child_process').spawn;
var net = require('net');
var http = require('http'),
    fs = require('fs');
// código baseado em https://gist.github.com/roccomuso/123b5d1ee82b80c1ede0d9c9a1509767
var port = 5678;
var server = net.createServer();

server.on('listening', function() {
    console.log('listening on ' + 'localhost:' + port);
});

server.on('connection', function(socket) {
    socket.on('data', function(data) {
        console.log("Arquivo solicitado: ../public/" + data);
        fs.readFile("../public/" + data, function (err, html) {
            if (err) {
                console.log("Erro ao encontrar o arquivo: not found");
                socket.write('Not found');
            } else {
                console.log("Arquivo encontrado, conteúdo sendo escrito no socket");
                socket.write(html);
            }
            socket.end();
        });
    });
});

server.on('end', function () {
    console.log('Connection end.')
});
server.on('close', function (hadError) {
    console.log('Connection closed', hadError ? 'because of a conn. error' : 'by client')
});

server.listen(port, 'localhost');
