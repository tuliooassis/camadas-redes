#!/bin/sh

# define portas e arquivos de saída
readonly PORT_LISTEN=54321;
readonly CLIENT_FILE=client.out;
readonly SERVER_PORT=12345;
readonly SERVER_IP=localhost

# fecha porta ao finalizar com CTRL+C
trap 'echo "Fechando a porta do cliente | port: ${PORT_LISTEN}"; fuser -k -n tcp "${PORT_LISTEN}"; exit' INT

echo "Iniciando cliente na porta: ${PORT_LISTEN} com arquivo: ${CLIENT_FILE}";
nc -k -l "${PORT_LISTEN}" > "${CLIENT_FILE}" &

echo "Conectando no servidor de ip: ${SERVER_IP}, na porta: ${SERVER_PORT} e esperando por resposta";

# aguardando o servidor estar pronto
nc -z "${SERVER_IP}" "${SERVER_PORT}";
isOpen=$?;
while [ ! "${isOpen}" -eq 0 ];
do
    nc -z "${SERVER_IP}" "${SERVER_PORT}";
    isOpen=$?;
done

# envia um oi para o servidor
echo "Olar" | nc -q 2 "${SERVER_IP}" "${SERVER_PORT}";

# verifica o arquivo de saída da porta até encontrar alguma resposta
while true;
do
    if [ -s "${CLIENT_FILE}" ]; then
        echo "Resposta do servidor: ";
        cat "${CLIENT_FILE}";

        echo "Fechando a porta do cliente | porta: ${PORT_LISTEN}";
        fuser -k -n tcp "${PORT_LISTEN}";
        exit 0;
    fi
done
