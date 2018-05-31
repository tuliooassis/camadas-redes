#!/bin/bash
source ../fisica/common.sh

# define portas e arquivos de saída
readonly PORT_LISTEN=54321;
readonly CLIENT_FILE=client.out;
readonly CLIENT_FILE_RECEIVE=client_receive.out;
readonly FILE_LOG=client.log;
readonly SERVER_PORT=12345;
readonly SERVER_IP=localhost;

# fecha porta ao finalizar com CTRL+C
trap 'escreveLog "Finalizando cliente e fechando a porta ${PORT_LISTEN}"; fuser -k -n tcp ${PORT_LISTEN}; exit' INT

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

removeLog;

nc -k -l "${PORT_LISTEN}" > "${CLIENT_FILE_RECEIVE}" &

escreveLog "Criando quadro"
echo $1 > ${CLIENT_FILE}
mensagem=$(cat $CLIENT_FILE)
quadro=$(criaQuadro ${mensagem});
echo ${quadro} > ${CLIENT_FILE}

escreveLog "Tentando enviar o quadro"
tentativa=$(( ( RANDOM % 10 )  + 1 ));
while [ $((${tentativa}%2)) -eq 0 ]; do
    escreveLog "Erro ao enviar, tentando novamente..."
    tentativa=$(( ( RANDOM % 10 )  + 1 ));
done

escreveLog "Eviando o quadro ${CLIENT_FILE} no IP ${SERVER_IP} na porta ${SERVER_PORT}";
cat ${CLIENT_FILE} | nc -q 2 "${SERVER_IP}" "${SERVER_PORT}";

escreveLog "Quadro enviado com sucesso!"

escreveLog "Aguardando resposta do servidor"
while true; do
    if [ -s "${CLIENT_FILE_RECEIVE}" ]; then
        escreveLog "Obtendo resposta do servidor"
        quadro=$(cat ${CLIENT_FILE_RECEIVE});
        mensagem=$(obterMensagem $quadro);
        escreveLog "Mensagem recebida no quadro: $(echo $mensagem)";
        if [ "$mensagem" != "not found" ]; then
            echo $mensagem > $1;
        fi
        escreveLog "Finalizando cliente, removendo arquivos e fechando a porta ${PORT_LISTEN}";
        fuser -k -n tcp "${PORT_LISTEN}";
        rm -f "${CLIENT_FILE_RECEIVE}";
        rm -f "${CLIENT_FILE}";
        rm -f "${FILE_LOG}";
        exit 0;
    fi
done
