#!/bin/bash
source ../fisica/common.sh

# define porta e arquivos de saída
readonly PORT_LISTEN=12345;
readonly SERVER_FILE=server.out;
readonly FILE_LOG=server.log;

readonly PORT_CLIENT=54321;
IP_CLIENT=localhost;

readonly PORT_SERVER_TRANS=15935;

# fecha porta ao finalizar com CTRL+C
trap 'escreveLog "Finalizando servidor e fechando a porta ${PORT_LISTEN}"; fuser -k -n tcp ${PORT_LISTEN}; exit' INT

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
	if [ "$IP_CLIENT" == "localhost" ]; then
		v_endDestino=$v_endOrigem;
	#se não for localhost pega MAC do outro pc
	else
		v_endDestino=$(arp ${IP_CLIENT} -a | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | tr -d ':')
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

escreveLog "Servidor iniciado"
escreveLog "Aguardando conexão na porta ${PORT_LISTEN}";
nc -k -l ${PORT_LISTEN} | tee ${SERVER_FILE} &

while true; do
    network=$(lsof -i:"${PORT_LISTEN}" | grep "localhost:${PORT_LISTEN} (ESTABLISHED)" | awk '{print $9}');
    if [ -s "${SERVER_FILE}" ] && [ ! -z "${network}" ]; then
        IP_CLIENT=$(echo $network | cut -d':' -f1);

        escreveLog "Quadro recebido"
        escreveLog "Obtendo mensagem recebida"

        quadro=$(cat ${SERVER_FILE});
        mensagem=$(obterMensagem $quadro);
        escreveLog "Mensagem recebida no quadro: $(echo $mensagem)";
        cp /dev/null ${SERVER_FILE};
        #echo "Mensagem recebida no quadro: $(echo $mensagem)";

        #solicita conteúdo para a camada de transporte e envia resposta para o arquivo temporário
        echo "$mensagem" | nc "localhost" "${PORT_SERVER_TRANS}" > ${SERVER_FILE};

        echo "Obtendo resposta da camada de transporte"
        page=$(cat ${SERVER_FILE});
        echo $page;
        echo "Respondendo com conteúdo de /$(echo $mensagem) para $IP_CLIENT:$PORT_CLIENT";
        quadro=$(criaQuadro ${page});
        echo $quadro | nc -q 2 "${IP_CLIENT}" "${PORT_CLIENT}";

        cp /dev/null ${SERVER_FILE};
    fi
done
