import socket
import subprocess
import shlex
HOST = '127.0.0.1'     # Endereco IP do Servidor
PORT = 34567            # Porta que o Servidor esta
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

s.bind((HOST, PORT))
s.listen(1)
while True:
    con, cliente = s.accept()
    print 'Conectado por', cliente
    msg = con.recv(1024)

    if msg.split(" ")[1] == "localhost" or msg.split(" ")[1] == "127.0.0.1":
        print "executando ../fisica/client.sh " + msg
        subprocess.call(shlex.split('../fisica/client.sh ' + msg))
    else:
        print "Host nao definido na tabela de roteamento"

    print 'Finalizando conexao do cliente', cliente
    con.close()
