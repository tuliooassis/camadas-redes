#!/bin/bash

# define porta e arquivos de saída
readonly PORT_LISTEN=12345;
readonly PORT_LISTEN_CLIENT=54321;
readonly SERVER_FILE=server.out;

# fecha porta ao finalizar com CTRL+C
trap 'echo "Fechando a porta do servidor | port: ${PORT_LISTEN}"; fuser -k -n tcp "${PORT_LISTEN}"; exit' INT

echo "Iniciando servidor na porta: ${PORT_LISTEN} com arquivo: ${SERVER_FILE}";
nc -k -l "${PORT_LISTEN}" | tee "${SERVER_FILE}" &

echo "Aguardando pela conexão...";

while true;
do
    tmpNetworkString=$(lsof -i:"${PORT_LISTEN}" | grep "localhost:${PORT_LISTEN} (ESTABLISHED)" | awk '{print $9}');
    echo -n "${tmpNetworkString}";
    if [ -s "${SERVER_FILE}" ] && [ ! -z "${tmpNetworkString}" ]; then
        answer=$(cat "${SERVER_FILE}");
        echo "Connection received on port ${PORT_LISTEN}...";
        incomingIP=$(echo $tmpNetworkString | cut -d':' -f1);
        incomingPort=$(echo $tmpNetworkString | cut -d'-' -f1 | cut -d':' -f2);
        echo ">>Incoming traffic IP: ${incomingIP}";
        echo ">>Incoming traffic Port: ${incomingPort}";
        echo "Answering on IP: ${incomingIP}, port: ${PORT_LISTEN_CLIENT}...";

        # aguardando o cliente estar pronto
        nc -z "${incomingIP}" "${PORT_LISTEN_CLIENT}";
        isOpen=$?;
        while [ ! "${isOpen}" -eq 0 ];
        do
            nc -z "${incomingIP}" "${PORT_LISTEN_CLIENT}";
            isOpen=$?;
        done

        # envia um oi
        echo "Oi, turu bom?" | nc -q 2 "${incomingIP}" "${PORT_LISTEN_CLIENT}";

        echo "Fechando a porta do servidor | porta: ${PORT_LISTEN}";
        fuser -k -n tcp "${PORT_LISTEN}";

        exit 0;
    fi
done
