import socket
import subprocess
HOST = '127.0.0.1'     # Endereco IP do Servidor
PORT = 34567            # Porta que o Servidor esta
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#dest = (HOST, PORT)
#tcp.connect(dest)
#orig = (HOST, PORT)


s.bind((HOST, PORT))
s.listen(1)
while True:
    con, cliente = s.accept()
    print 'Conectado por', cliente
    while True:
        msg = con.recv(1024)
        if not msg: break
        print cliente, msg
	print "Executando a camada fisica"
	subprocess.call(['../fisica/client.sh','msg'])
    print 'Finalizando conexao do cliente', cliente
    con.close()

