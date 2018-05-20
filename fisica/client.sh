#!/bin/bash

# define portas e arquivos de saída
readonly PORT_LISTEN=54321;
readonly CLIENT_IP=localhost;
readonly CLIENT_AUX=client.aux;
readonly CLIENT_FILE=client.out;
readonly CLIENT_LOG=client.log;
readonly SERVER_PORT=12345;
readonly SERVER_IP=localhost;

# fecha porta ao finalizar com CTRL+C
trap 'escreveLog "Finalizando cliente"; exit' INT

escreveLog(){
    echo -n $(date) >> ${CLIENT_LOG};
    echo ": $*" >> ${CLIENT_LOG};
}

# código conversor retirado de https://unix.stackexchange.com/questions/98948/ascii-to-binary-and-binary-to-ascii-conversion-tools
ordbin(){
  a=$(printf '%08d' "'$1")
  echo "obase=2; $a" | bc
}

converterAsciiParaBinario(){
   echo -n $* | while IFS= read -r -n1 char
    do
        result=$(ordbin $char | tr -d '\n')
        if [ $result == "0" ]; then
            echo "00100000";
            continue
        fi
        while [ ${#result} -lt 8 ]; do
            result="0$result"
        done
	    echo "$result "
    done
}

junta(){
    local IFS="$1";
    shift;
    echo "$*";
}

criaQuadro (){
    v_mensagem=$*;
    #Início cabeçalho da camada física
        #Preâmbulo (7 bytes) de 0s e 1s alternados para alertar a chegada de um quadro e permitir a sincronização
        v_preambulo='10101010101010101010101010101010101010101010101010101010';

        #Inicio do quadro (1 byte) com valor 10101011 que indica o início do quadro, alertando sobre a última chance de sincronizar.
        # o 11 alerta que o campo seguinte é o endereço de destino
        v_inicioQuadro='10101011';
    #Fim cabeçalho da camada física

	#Endereço MAC de origem (12 bytes) é o endereço da camada de enlace do reme tente do pacote
    v_endOrigem=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address  | tr -d ':');
    v_endOrigemBin=$(converterAsciiParaBinario ${v_endOrigem});
    v_endOrigemBin=$(junta "" ${v_endOrigemBin});

    #Endereço MAC de destino (12 bytes) é o endereço da camada de enlace de destino que receberá o pacote
	#se o IP do servidor for localhost, MAC de origem = MAC destino
	if [ "$SERVER_IP" == "localhost" ]; then
		v_endDestino=$v_endOrigem;
	#se não for localhost pega MAC do outro pc
	else
		v_endDestino=$(arp ${SERVER_IP} -a | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | tr -d ':')
	fi
    v_endDestinoBin=$(converterAsciiParaBinario ${v_endDestino});
    v_endDestinoBin=$(junta "" ${v_endDestinoBin});

    #Tipo (2 bytes) possui o protocolo da camada superior cujo pacote está encapsulado no quadro. Ex.: IP
    v_tipo='0000000011111111'

    #Dados em binário
    v_dados=${v_mensagem};
    v_dadosBin=$(converterAsciiParaBinario ${v_dados});
    v_dadosBin=$(junta "" ${v_dadosBin});

    #CRC: detecção de erros (4 bytes)
    v_crc='11111111111111111111111111111111';

    quadro="${v_preambulo}${v_inicioQuadro}${v_endDestinoBin}${v_endOrigemBin}${v_tipo}${v_dadosBin}${v_crc}";
    echo $quadro;
}

if [ -e ${CLIENT_LOG} ]; then
    rm ${CLIENT_LOG} ;
    escreveLog "Removendo arquivo antigo de log"
fi

escreveLog "Criando quadro"
nc -l -w 3 ${CLIENT_IP} ${PORT_LISTEN} > ${CLIENT_AUX}
cat ${CLIENT_AUX} > ${CLIENT_FILE}
mensagem=$(cat $CLIENT_FILE)
quadro=$(criaQuadro ${mensagem});
echo ${quadro} > ${CLIENT_FILE}

escreveLog "Tentando enviar o quadro"
tentativa=$(( ( RANDOM % 10 )  + 1 ));
while [ $((${tentativa}%2)) -eq 0 ]; do
    escreveLog "Erro ao enviar, tentando novamente..."
    tentativa=$(( ( RANDOM % 10 )  + 1 ));
done

escreveLog "Eviando o quadro ${CLIENT_FILE} na porta ${PORT_LISTEN}";
nc ${SERVER_IP} ${SERVER_PORT} < ${CLIENT_FILE};

escreveLog "Quadro enviado com sucesso!"

escreveLog "Finalizando o cliente";
exit 0;
