#!/bin/bash

escreveLog(){
    echo -n $(date) >> ${FILE_LOG};
    echo ": $*" >> ${FILE_LOG};
}

removeLog(){
    if [ -e ${FILE_LOG} ]; then
        rm ${FILE_LOG} ;
        escreveLog "Removendo arquivo antigo de log"
    fi
}

obterMensagem (){
    quadro=$1;
    mensagem=${quadro:272}
    mensagem=${mensagem:0:$((${#mensagem}-32))};
    mensagem=$(converterBinarioParaAscii $mensagem);
    echo $mensagem;
}

# código conversor retirado de https://unix.stackexchange.com/questions/98948/ascii-to-binary-and-binary-to-ascii-conversion-tools
chrbin() {
        echo $(printf \\$(echo "ibase=2; obase=8; $1" | bc))
}

ordbin(){
  a=$(printf '%08d' "'$1")
  echo "obase=2; $a" | bc
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
