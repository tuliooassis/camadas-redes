#!/bin/bash

# define porta e arquivos de saída
readonly PORT_LISTEN=12345;
readonly PORT_LISTEN_CLIENT=54321;
readonly SERVER_FILE=server.out;
readonly SERVER_LOG=server.log;
readonly TMQ=1;
CLIENT_IP=localhost;
CLIENT_PORT=localhost;
# fecha porta ao finalizar com CTRL+C
trap 'escreveLog "Fechando a porta do servidor | port: ${PORT_LISTEN}"; fuser -k -n tcp "${PORT_LISTEN}"; escreveLog "Servidor finalizado"; exit' INT

obterIpCliente(){
    OK=false;
    while [ OK != "true" ]; do
        tmpNetworkString=$(lsof -i:"${PORT_LISTEN}" | grep "localhost:${PORT_LISTEN} (ESTABLISHED)" | awk '{print $9}');
        if [ -s "${SERVER_FILE}" ] && [ ! -z "${tmpNetworkString}" ]; then
            OK=true;
            CLIENT_IP=$(echo $tmpNetworkString | cut -d':' -f1);
            CLIENT_PORT=$(echo $tmpNetworkString | cut -d'-' -f1 | cut -d':' -f2);
        fi
    done
}

escreveLog(){
    echo -n $(date) >> ${SERVER_LOG};
    echo ": $*" >> ${SERVER_LOG};
}

# código conversor retirado de https://unix.stackexchange.com/questions/98948/ascii-to-binary-and-binary-to-ascii-conversion-tools
ordbin(){
  a=$(printf '%d' "'$1")
  echo "obase=2; $a" | bc
}

chrbin() {
        echo $(printf \\$(echo "ibase=2; obase=8; $1" | bc))
}

converterAsciiParaBinario(){
   echo -n $* | while IFS= read -r -n1 char
    do
        result=$(ordbin $char | tr -d '\n')
        echo $result
       # echo -n " "
    done
}

converterBinarioParaAscii() {
    for bin in $*
    do
        chrbin $bin | tr -d '\n'
    done

}

junta(){ local IFS="$1"; shift; echo "$*"; }

if [ -e ${SERVER_LOG} ]; then
    rm ${SERVER_LOG} ;
    escreveLog "Removendo arquivo antigo de log"
fi

while true; do
    escreveLog "Iniciando servidor na porta: ${PORT_LISTEN} com arquivo: ${SERVER_FILE}";
    nc -I $TMQ -O $TMQ -k -l "${PORT_LISTEN}" | tee "${SERVER_FILE}" &

    escreveLog "Aguardando pela conexão...";

    while true; do
        content=$(cat ${SERVER_FILE});
        content=${content:0:8};
        #echo "content ${content}";
        case ${content} in
            "TMQ")
                #obterIpCliente;
                escreveLog "Cliente conectado | ip: ${CLIENT_IP} porta: ${CLIENT_PORTA}";
                escreveLog "Mensagem recebida: ${content}";
                escreveLog "Enviando TMQ";
                echo "$TMQ" | nc -q 2 "${CLIENT_IP}" "${PORT_LISTEN_CLIENT}";
                ;;
            "10101010")
                escreveLog "Recebendo quadro";
                v_mensagem=$(cat ${SERVER_FILE});
                v_mensagem="${v_mensagem:352}";
                v_mensagem="${v_mensagem:0:$((${#v_mensagem}-32))}";
                #v_mensagem=$(converterBinarioParaAscii ${v_mensagem});
                escreveLog "Mensagem recebida no quadro: ${v_mensagem}";
                echo "OK" | nc -q 2 "${CLIENT_IP}" "${PORT_LISTEN_CLIENT}";
                ;;
            "FIM")
                escreveLog "Mensagem recebida: ${content}";
                escreveLog "Cliente desconectado | porta: ${PORT_LISTEN}"
                ;;
            *)
            ;;
        esac
        cat /dev/null > "${SERVER_FILE}";
    done
done
