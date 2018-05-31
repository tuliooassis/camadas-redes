const port = 9876

var express = require('express');
var app = express();
var http = require('http'),
    fs = require('fs');

var client = app.listen(port, function() {
    console.log(`Ready on port ${port}`);
});

// rota que deve ser utilizada quando o arquivo não existe no Servidor
// é necessário o ip e a porta do servidor onde o arquivo está
app.get('/:SERVER_IP/:SERVER_PORT/:FILE_NAME', function (req, res, next) {
  const exec = require('child_process').exec;
  var execFisica = exec(`bash ../fisica/client.sh ${req.params.FILE_NAME} ${req.params.SERVER_IP} ${req.params.SERVER_PORT}`,
          (error, stdout, stderr) => {
              fs.readFile(`${req.params.FILE_NAME}`, function (err, html) {
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

              if (error !== null) {
                  console.log(`exec error: ${error}`);
              }
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
