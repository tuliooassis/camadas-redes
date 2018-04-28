#!/bin/bash

# define porta e arquivos de saída
readonly PORT_LISTEN=12345;
readonly SERVER_FILE=server.out;
readonly SERVER_LOG=server.log;

# fecha porta ao finalizar com CTRL+C
trap 'escreveLog "Finalizando servidor"; exit' INT

escreveLog(){
    echo -n $(date) >> ${SERVER_LOG};
    echo ": $*" >> ${SERVER_LOG};
}

# código conversor retirado de https://unix.stackexchange.com/questions/98948/ascii-to-binary-and-binary-to-ascii-conversion-tools
chrbin() {
        echo $(printf \\$(echo "ibase=2; obase=8; $1" | bc))
}

converterBinarioParaAscii() {
    for bin in $*
    do
        for (( i = 0; i < ${#bin}; i+=8 )); do
            conv=${bin:i:8};
            result=$(chrbin $conv | tr -d '\n');

            if [ $conv == "00100000" ]; then
                palavra=$(junta "" ${palavra});
                echo "$palavra"
                unset palavra
                continue;
            fi
            palavra=$palavra$result;
        done
        palavra=$(junta "" ${palavra});
        echo $palavra
    done
}

junta(){
    local IFS="$1";
    shift;
    echo "$*";
}

if [ -e ${SERVER_LOG} ]; then
    rm ${SERVER_LOG} ;
    escreveLog "Removendo arquivo antigo de log"
fi

escreveLog "Servidor iniciado"

while true; do
    escreveLog "Aguardando conexão na porta ${PORT_LISTEN}";
    nc -l -p ${PORT_LISTEN} > ${SERVER_FILE};

    escreveLog "Quadro recebido"
    escreveLog "Obtendo mensagem recebida"

    quadro=$(cat ${SERVER_FILE})
    mensagem=${quadro:272}
    mensagem="${mensagem:0:$((${#mensagem}-32))}";
    mensagem=$(converterBinarioParaAscii $mensagem);
    escreveLog "Mensagem recebida no quadro: $(echo $mensagem)";

    sleep 5
done
