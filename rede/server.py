import socket
HOST = '127.0.0.1'     # Endereco IP do Servidor
PORT = 65535           # porta camada fisica
PORT_TRANS = 15935	#porta camada de transporte
BUFFER_SIZE = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((HOST, PORT))
s.listen(1)
while True:
	con, server = s.accept()
	s2 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	dest = (HOST, PORT_TRANS)
	s2.connect(dest)
    	print 'Conectado por', server
        msg = con.recv(1024)
    	print server, msg
	s2.send (msg)
	data = s2.recv(BUFFER_SIZE)
	s2.close()
	print 'Enviando conteudo para a camada fisica'
	con.send(data);
	print "received data:", data
    	print 'Finalizando conexao do server', server
    	con.close()
