const http = require('http')
const port = 54321
const ip = 'localhost'
var fs = require('fs');
const server = http.createServer((req, res) => {
  	fs.readFile('./' + (req.url == '/' ? '/index.html' : 		req.url), function (err,data) {
    	if (err) {
      		res.writeHead(404);
      		res.end("Not Found");
      		return;
    	}
    	res.writeHead(200);
    	res.end(data);
	});
})

server.listen(port, ip, () => {
  console.log(`Servidor rodando em http://${ip}:${port}`)
  console.log('Para derrubar o servidor: ctrl + c');
})
