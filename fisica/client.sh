#!/bin/bash

# define portas e arquivos de saída
readonly PORT_LISTEN=54321;
readonly CLIENT_FILE=client.out;
readonly SERVER_PORT=12345;
readonly SERVER_IP=localhost

converterAsciiParaBinario(){
    v_mensagem="$1";
    v_comando="";
    for (( i = 2; i <= ${#1} + 1; i++ )); do
        v_comando="${v_comando} \$$i";
    done
    v_comando="${v_comando}";

    v_binario="echo ${v_mensagem} | xxd -b | awk '{print ${v_comando}}'"; #erro aqui, n sei pq
    v_binario=$(${v_binario});
    echo "imprimindo binario ${v_binario}";
    return ${v_binario};
}

criaQuadro (){
        v_mensagem=$1;

        #Início cabeçalho da camada física
            #Preâmbulo (7 bytes) de 0s e 1s alternados para alertar a chegada de um quadro e permitir a sincronização
            v_preambulo='10101010101010101010101010101010101010101010101010101010';

            #Inicio do quadro (1 byte) com valor 10101011 que indica o início do quadro, alertando sobre a última chance de sincronizar.
            # o 11 alerta que o campo seguinte é o endereço de destino
            v_inicioQuadro='10101011';
        #Fim cabeçalho da camada física

        #Endereço MAC de destino (6 bytes) é o endereço da camada de enlace de destino que receberá o pacote
        v_endDestino=$(arp ${SERVER_IP} -a | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}');
        #v_endDestino=$(echo "obase=2;${v_endDestino}" | bc10);
        echo "${v_endDestino}";

        #Endereço MAC de origem (6 bytes) é o endereço da camada de enlace do remetente do pacote
        v_endOrigem=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address);
        #v_endOrigem=$(echo "obase=2;${v_endOrigem}" | bc10);
        echo "${v_endOrigem}";

        #Tipo (2 bytes) possui o protocolo da camada superior cujo pacote está encapsulado no quadro. Ex.: IP
        v_tipo='0000000011111111'

        #Dados
        #v_dados=$(echo "obase=2;${v_mensagem}" | bc10);
        echo ${v_dados};

        #CRC: detecção de erros (4 bytes)
        v_crc='11111111111111111111111111111111';

        quadro="${v_preambulo} ${v_inicioQuadro} ${v_endDestino} ${v_endOrigem} ${v_tipo} ${v_dados} ${v_crc}";

        return ${quadro};
}
converterAsciiParaBinario "Ola";
quadd=$(criaQuadro "oi");
echo "imprimindo";
echo "${quadd}";

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
