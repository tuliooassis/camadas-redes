import socket
HOST = 'localhost'     # Endereco IP do Servidor
PORT = 34567            # Porta que o Servidor esta
tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#dest = (HOST, PORT)
#tcp.connect(dest)
orig = (HOST, PORT)
tcp.bind(orig)
tcp.listen(1)
while True:
    con, resultado = tcp.accept()
    print 'Resultado: ', resultado, con
    while True:
        msg = con.recv(1024)
        if not msg: break
        print 'mensagem: ', msg
    print 'Finalizando conexao do cliente', resultado
    con.close()

#msg = raw_input("Digite uma mensagem para enviar ao servidor:")
#while msg <> '\x18':
 #   tcp.send (msg)
  #  msg = raw_input()
#tcp.close()

