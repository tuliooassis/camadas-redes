	 	 	
# camadas-redes 
Implementação da Pilha de Protocolos TCP/IP, referentes ao trabalho prático de Redes de Computadores I 
Grupo: Luiza Souza, Marcela Viana, Túlio Moreira, Vinícius Silveira

Link para vídeo explicativo:
https://www.youtube.com/watch?v=PBUNACHxNv8&feature=youtu.be 

## Camada física: Shell Script

Requisitos:
> Instalação do comando "arp" no terminal. Pode ser feito com o seguinte comando:
- sudo apt-get install net-tools

Para a implementação da primeira parte da pilha de protocolos (camada física) foi utilizada a linguagem Shell Script. O objetivo é a implementação do modelo cliente-servidor usando uma conexão TCP para fazer a transferência entre dois hosts. A implementação foi dividida em dois códigos: código do servidor (server.sh) e código do cliente (client.sh). O Quadro Ethernet enviado do cliente para o servidor em um arquivo texto está dentro da definição RFC (convertido para bits). Há também dois logs (log do servidor e log do cliente) para que seja possível acompanhar o funcionamento dos programas.

### client.sh
Foi definido primeiro algumas variáveis de apenas leitura, como por exemplo, a porta que vai ser escutada, as variáveis que referenciam os arquivos de log e o servidor IP que será utilizado.

Há uma trap que identifica o sinal CTRL+C que escreve no log que está finalizando o cliente quando recebe o sinal (o cliente poderá enviar quadros enquanto não receber o sinal CTRL+C para finalizar o programa).

As funções em seguida são para escrever no log do cliente; converter um texto ASCII simples para binário (o link com a fonte da função está presente como comentário); e uma função para juntar partes de um binário.

A função de criação do quadro em seguida é um pouco mais complexa. Primeiramente, guardamos a mensagem recebida do arquivo texto em uma variável. Guardamos na variável “v_preambulo” o preâmbulo do quadro, que possui 7 bytes com números alternados entre 0 e 1 e indica a chegada de um quadro novo e solicita permissão de sincronização. O quadro é iniciado com 1 byte (valor 10101011) que indica o início do quadro, alertando sobre a última chance de sincronizar. Os dois últimos bits desse campo (11) alertam que o campo seguinte é o endereço de destino. Os campos anteriormente citados formam o cabeçalho da camada física.

Ainda dentro da função de criação do quadro, utilizamos um comando para recuperar o MAC Address de origem e guardar em uma variável convertido para binário. Para recuperar o MAC Address de destino primeiro fazemos a verificação de o localhost está sendo utilizado: se esse for o caso o MAC de origem será igual ao MAC de destino; se não o MAC de destino será recuperado com um outro comando específico. Após isso foi definido o tipo do protocolo da camada superior (2 bytes), como por exemplo o protocolo IP. Salvamos os dados da mensagem efetivamente a ser transmitida em uma variável já convertido para binário. O quadro também possui uma variável para detecção de erros, “v_crc”, que possui 4 bytes. Para finalizar a criação do quadro todas as variáveis anteriormente citadas são concatenadas para formar o quadro.

Após a função de criação do quadro, há uma função para remoção de logs antigos, com o objetivo de evitar o acúmulo de arquivos de logs de várias transferências de arquivos (estamos interessados apenas na transferência mais recente).

Após isso iniciou-se a criação do arquivo de log do cliente. Escreve-se no log “Criando quadro”, e o arquivo .txt é lido e enviado para a função de criação do quadro, que retorna o quadro enviado. Após isso escreve-se “Tentando enviar o quadro”, e uma tentativa de envio será feita utilizando números aleatórios; se o número aleatório gerado for par há um erro no envio e a mensagem “Erro ao enviar, tentando novamente...” é escrita no log, indicando que não foi possível enviar o quadro (isso simula uma colisão de pacotes por exemplo) e uma novas tentativas de envio são feitas até que seja possível enviar o quadro. Quando for possível enviar, escreve-se no log “Enviando o quadro [identificador do quadro] na porta [identificador da porta]” e o quadro é efetivamente enviado utilizando-se o comando nc (netcat, esse é o comando mais importante do programa, que abre uma conexão TCP conectando cliente e servidor para o envio do quadro). Após isso é escrito no log do cliente “Quadro enviado com sucesso” e depois “Finalizando o cliente” e finaliza-se o código do cliente.


### server.sh
Foram definidas da mesma maneira que no cliente algumas variáveis importantes de apenas leitura, referentes aos endereços dos arquivos de log e porta que irá escutar.

Também há a presença do comando trap que verifica o sinal CTRL+C para finalização do programa (o servidor ficará rodando e disponível para o recebimento de quadros enquanto não receber o sinal CTRL+C).

A função de escrita no log também é semelhante à presente do código do cliente. No código do servidor há uma função que faz a conversão reversa (do binário para ASCII, o link da fonte da função também está presente no código como comentário) e há ainda também a função de junção de partes de um binário e a função para remover logs antigos. Até essa parte os códigos do cliente e servidor são muito similares.

Após isso começamos a escrever no log do servidor. Escrevemos a mensagem “Servidor iniciado”. Escrevemos em seguida a mensagem “Aguardando conexão na porta [identificador da porta]” e executamos o comando nc (netcat) de conexão TCP do servidor que irá ouvir de uma determinada porta específica (esse é o comando mais importante do código do servidor). Escreve-se no log as mensagens “Quadro recebido” e “Obtendo mensagem recebida”. Os dados recebidos em “SERVER_FILE” serão salvos na variável “quadro”. A extração da mensagem do quadro é realizada recuperando-se a informação a partir da posição 272 do quadro (onde a mensagem está efetivamente) e salva-se na variável “mensagem” e retira-se as 32 últimas posições que também são informações adicionais e não fazem parte da mensagem enviada. A mensagem será convertida do binário para o ASCII e é escrito no log do servidor “Mensagem recebida no quadro: [mensagem recebida]”. O comando sleep faz com que o servidor aguarde 5 segundos para ler o próximo quadro e o servidor irá tentará ler quadros enquanto não receber o sinal de CTRL+C para ser finalizado.


O funcionamento dos códigos do cliente e do servidor assim como mais detalhes de como a implementação foi feita podem ser conferidos no vídeo explicativo (link no início da documentação).
