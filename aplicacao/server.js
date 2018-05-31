var spawn = require('child_process').spawn;
var net = require('net');
var http = require('http'),
    fs = require('fs');
// código baseado em https://gist.github.com/roccomuso/123b5d1ee82b80c1ede0d9c9a1509767
var port = 5678;
var server = net.createServer(function(socket) {
    var sh = (process.platform === 'win32') ? spawn('cmd') : spawn('/bin/bash');
    sh.stdin.resume();
    sh.stdout.on('data', function (data) {
        //console.log("../public/" + data);
        fs.readFile("../public/" + data, function (err, html) {
            if (err) {
                //console.log("error: " + err);
                socket.write('Not found');
            } else {
                //console.log("html: " + html);
                socket.write(html);
            }
            socket.end();
        });
    });

    socket.on('data', function (data) {
        sh.stdin.write(data);
    });
    socket.on('end', function () {
        console.log('Connection end.')
    });
    socket.on('close', function (hadError) {
        console.log('Connection closed', hadError ? 'because of a conn. error' : 'by client')
    });

});

server.listen(port, 'localhost');
