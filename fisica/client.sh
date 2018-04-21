#!/bin/bash

# define portas e arquivos de saída
readonly PORT_LISTEN=54321;
readonly CLIENT_FILE=client.out;
readonly CLIENT_LOG=client.log;
readonly SERVER_PORT=12345;
readonly SERVER_IP=localhost;

# fecha porta ao finalizar com CTRL+C
trap 'escreveLog "Fechando a porta do cliente | port: ${PORT_LISTEN}"; fuser -k -n tcp "${PORT_LISTEN}"; escreveLog "Cliente finalizado"; exit' INT

escreveLog(){
    echo -n $(date) >> ${CLIENT_LOG};
    echo ": $*" >> ${CLIENT_LOG};
}

ordbin(){
  a=$(printf '%08d' "'$1")
  echo "obase=2; $a" | bc
}

converterAsciiParaBinario(){
   echo -n $* | while IFS= read -r -n1 char
    do
        result=$(ordbin $char | tr -d '\n')
        while [ ${#result} -lt 8 ]; do
            result="0$result"
        done
	    echo $result
    done
}

junta(){ local IFS="$1"; shift; echo "$*"; }

criaQuadro (){
    v_mensagem=$*;
    #Início cabeçalho da camada física
        #Preâmbulo (7 bytes) de 0s e 1s alternados para alertar a chegada de um quadro e permitir a sincronização
        v_preambulo='10101010101010101010101010101010101010101010101010101010';

        #Inicio do quadro (1 byte) com valor 10101011 que indica o início do quadro, alertando sobre a última chance de sincronizar.
        # o 11 alerta que o campo seguinte é o endereço de destino
            v_inicioQuadro='10101011';
    #Fim cabeçalho da camada física

	#Endereço MAC de origem (17 bytes) é o endereço da camada de enlace do reme tente do pacote
    v_endOrigem=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address);
    #echo "MAC de origem: ${v_endOrigem}";
    v_endOrigemBin=$(converterAsciiParaBinario ${v_endOrigem});
    v_endOrigemBin=$(junta "" ${v_endOrigemBin});
    #echo "MAC de origem binário: ${v_endOrigemBin}";


    #Endereço MAC de destino (17 bytes) é o endereço da camada de enlace de destino que receberá o pacote
	#se o IP do servidor for localhost, MAC de origem = MAC destino
	if [ "$SERVER_IP" == "localhost" ]; then
		v_endDestino=$v_endOrigem;
	#se não for localhost pega MAC do outro pc
	else
		v_endDestino=$(arp ${SERVER_IP} -a | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
	fi
    #echo "MAC de destino: ${v_endDestino}";
    v_endDestinoBin=$(converterAsciiParaBinario ${v_endDestino});
    v_endDestinoBin=$(junta "" ${v_endDestinoBin});
    #echo "MAC de destino binário: ${v_endDestinoBin}";

    #Tipo (2 bytes) possui o protocolo da camada superior cujo pacote está encapsulado no quadro. Ex.: IP
    v_tipo='0000000011111111'

    #Dados em binário
    v_dados=${v_mensagem};
    #echo "Mensagem do quadro: $v_dados";
    v_dadosBin=$(converterAsciiParaBinario ${v_dados});
    #echo "Mensagem do quadro binário1: $v_dadosBin";
    v_dadosBin=$(junta "" ${v_dadosBin});
    #echo "Mensagem do quadro binário: $v_dadosBin";

    #CRC: detecção de erros (4 bytes)
    v_crc='11111111111111111111111111111111';

    quadro="${v_preambulo}${v_inicioQuadro}${v_endDestinoBin}${v_endOrigemBin}${v_tipo}${v_dadosBin}${v_crc}";
    #echo "Quadro completo: ${quadro}"
    echo "${quadro}";
}

if [ -e ${CLIENT_LOG} ]; then
    rm ${CLIENT_LOG} ;
    escreveLog "Removendo arquivo antigo de log"
fi

escreveLog "Criando quadro"
quadro=$(criaQuadro $*);


escreveLog "Iniciando cliente na porta: ${PORT_LISTEN} com arquivo: ${CLIENT_FILE}";
nc -k -l "${PORT_LISTEN}" > "${CLIENT_FILE}" &

escreveLog "Conectando no servidor de ip: ${SERVER_IP}, na porta: ${SERVER_PORT} e esperando por resposta";


escreveLog "Aguardando o servidor ficar pronto"
nc -z "${SERVER_IP}" "${SERVER_PORT}";
isOpen=$?;
while [ ! "${isOpen}" -eq 0 ];
do
    nc -z "${SERVER_IP}" "${SERVER_PORT}";
    isOpen=$?;
done

# solicita TMQ para o servidor
escreveLog "Solicita TMQ";
echo "TMQ" | nc -q 2 "${SERVER_IP}" "${SERVER_PORT}";
escreveLog "Recebe TMQ"
TMQ=$(cat ${CLIENT_FILE});
escreveLog "Fechando a porta do cliente | porta: ${PORT_LISTEN}";
fuser -k -n tcp "${PORT_LISTEN}";

escreveLog "Iniciando cliente na porta: ${PORT_LISTEN} com arquivo: ${CLIENT_FILE}";
nc -I $TMQ -O $TMQ -k -l "${PORT_LISTEN}" | tee "${CLIENT_FILE}" &

escreveLog "Envia quadro para o servidor"
echo "${quadro}" | nc -q 2 "${SERVER_IP}" "${SERVER_PORT}";

escreveLog "Envia finalizar para o servidor"
echo "FIM" | nc -q 2 "${SERVER_IP}" "${SERVER_PORT}";

escreveLog "Fechando a porta do cliente | porta: ${PORT_LISTEN}";
fuser -k -n tcp "${PORT_LISTEN}";
exit 0;
