const port = 9876;
const portTrans = 53951;
//curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
//sudo apt-get install -y nodejs
var net = require('net');
var express = require('express');
var app = express();
var http = require('http'),
    fs = require('fs');

var client = app.listen(port, function() {
    console.log(`Ready on port ${port}`);
});

var clientTrans = new net.Socket();


// rota que deve ser utilizada quando o arquivo não existe no Servidor
// é necessário o ip e a porta do servidor onde o arquivo está
app.get('/:SERVER_IP/:SERVER_PORT/:FILE_NAME', function (req, res, next) {

    clientTrans.connect(portTrans, function() {
        console.log('Enviando conteúdo para a camada de transporte');
        clientTrans.write(`${req.params.FILE_NAME} ${req.params.SERVER_IP} ${req.params.SERVER_PORT}`);
        console.log('Aguardando construção do arquivo');
        setTimeout(function() {
            fs.readFile(`${req.params.FILE_NAME}`, function (err, html) {
                if (err) {
                    res.writeHeader(404, {"Content-Type": "text/html"});
                    res.write("Not found");
                    console.log("Erro ao encontrar o arquivo: not found");
                    res.end();
                } else {
                    res.writeHeader(200, {"Content-Type": "text/html"});
                    res.write(html);
                    res.end();
                }
            });
            console.log("Arquivo exibido.")
            clientTrans.destroy();
        }, 5000);
    });

});

// rota que pode ser utilizada para arquivos já existentes no servidor
app.get('/:FILE_NAME', function (req, res, next) {
    var fileName = req.params.FILE_NAME;
    fs.readFile(fileName, function (err, html) {
        if (err) {
            res.writeHeader(404, {"Content-Type": "text/html"});
            res.write("Not found");
            res.end();
        } else {
            res.writeHeader(200, {"Content-Type": "text/html"});
            res.write(html);
            res.end();
        }
    });
});
