#!/bin/bash

#---------------------------------------------------------------------------#
# Data: 31 de Agosto de 2016
# Criador por: Juliano Santos [x_SHAMAN_x]
# Script: netfile.sh
# Descrição: Script para busca de documentações na internet.
#			 Para iniciar a pesquisa, basta digitar o nome do título que
#			 deseja procurar e clicar em pesquisar.
#			 Observação: Espaços são permitidos.
# --------------------------------------------------------------------------#

# Script
SCRIPT=`basename "$0"`

# Verifica se o comando está instalado.
if ! LYNX=`which lynx`; then
	echo "$SCRIPT: erro: 'lynx' não está instalado."; exit 1; fi

# Suprime errors
exec 2>/dev/null

# QUERY de busca (google) :)
URL="http://google.com/search?hl=en&safe=off&q="

# Arquvos temporários
LINK=/tmp/links
PRO=/tmp/pro

main()
{
	rm $LINK $PRO 				# Remove os arquivos temporários
	kill -9 $PID $DPID $WPID 	# Mata o processo em background

	# Janela principal
	# Exibe a armazena os dados em OPT 
	OPT=`yad --center \
				--width=300 \
				--fixed \
				--title="$SCRIPT - [x_SHAMAN_x]" \
				--text='Digite o nome do título que deseja pesquisar.\nExemplo: Linux\n\n<b>[Num. Pesquisas]</b> - Define a quantidade de pesquisas\nque seram realizadas. Quanto maior o número, maior\no resultado.' \
				--form \
				--field='Título:' '' \
				--field='Tipo do arquivo:':CB 'pdf!doc!docx!txt!rtf!pps!ppt!pptx!ott!odt!odp!otp' \
				--field='Num. pesquisas:':NUM '1!1..100!1' \
				--field='Salvar em:':DIR \
				--button='Sair!gtk-quit!Sai do script':252 \
				--button='Pesquisar!!Iniciar pesquisa.':0`

	# Retorno
	RETVAL=$?

	# Extrai os valores de 'OPT' separados pelo delimitador '|'
	SEARCH=`echo $OPT | cut -d'|' -f1`					# Título a ser pesquisado
	EXT=`echo $OPT | cut -d'|' -f2`
	COUNT=`echo $OPT | cut -d'|' -f3 | cut -d',' -f1`	# Número de pesquisas
	DIR=`echo $OPT | cut -d'|' -f4`						# Diretório

	# Remove extensão em 'SEARCH' (se houver)
	SEARCH=${SEARCH%%.*}		
	
	# Checa o código de retorno da janela
	if [ $RETVAL -eq 252 ]; then
		exit 0	# Sair|Fechar:252 - Finaliza o script
	# Se 'SEARCH' for nulo, exibe mensagem de erro e retorna a função principal
	elif [ ! "$SEARCH" ]; then
		yad --title='Informação' \
			--text='Digite o nome do título que deseja pesquisar.' \
			--image=gtk-dialog-info \
			--center \
			--fixed \
			--form \
			--height=100 \
			--button='OK':0 

		main	# Função principal
	fi

	# Substitui os espaços contidos em 'SEARCH' por '%20' (HTML Encoding), insere a extensão do arquivo e armazena em 'STRING'
	# Exemplo: viva o linux = viva%20o%20linux.extensão
	STRING="`echo $SEARCH | sed 's/ /%20/g'`.$EXT"
	# Concatena QUERY de busca com a 'STRING' e '&start=' (resultado por página) e armazena em 'URI'
	URI="$URL$STRING&start="
	# Subtrai '-1' do valor de 'COUNT' (Num. Pesquisas) e insere '0' no final do valor.
	# A subtração e inserção do '0' no final, refere-se ao resultados por página (=10) na QUERY.
	# Exemplo: COUNT=2 - 1 = 1 + '0' = 10
	((COUNT--)); COUNT+=0

	# Inicia o loop de 0 a 'COUNT' com intervalos de '10 (resultados por página)'.
	# Exemplo: COUNT=40
	# 0 10 20 30 40
	for C in `seq 0 10 $COUNT`
	do
		# Insere o valor de 'C' no final 'URI'
		# Executa um dump na URI para obter as urls, remove toda expressão do inicio de cada linha até
		# http, cria um RHS do inicio de http até 'extensão do arquivo' e remove toda expressão depois 'da extensão' até o final da linha.
		# Remove itens duplicados, exclui as linhas com links que contém a expressão 'google' e salva em 'LINK'
		$LYNX --dump $URI$C | sed -n "s/.*http\(.*$EXT\).*/http\1/pg" | sort -u | grep -v google >> $LINK
	done &	# Loop executando em background

	# Armazena o 'PID' do processo do loop
	PID=$!

	# Exibe a janela de pesquisa até o loop acabar
	while ps -q $PID &>/dev/null; do
		echo "# Título: $SEARCH\nTipo: $EXT\nPesquisando..."
		sleep 0.5
	done | yad --title="$SCRIPT" \
				--center \
				--progress \
				--fixed \
				--pulsate \
				--auto-kill \
				--auto-close 
	
	# Subfunção 'list_file'
	list_file()
	{
		# Mata os processos em background
		kill -9 $WPID $DPID `pidof yad`
		# Total de links encontrados
		TOTAL=`cat $LINK | wc -l`
	
		# Imprime o conteúdo do arquivo aplicando as regex's:
		# Cria um RHS pegando todos os caracteres entre as '/', obtem assim o dominio do site. Insere um espaço separando o link do arquivo
		# Exclui todas as 'extensões inválidas', rediciona a saida para o awk que verifica se o campo 'dominio' for nulo, aplica o valor
		# padrão 'Desconhecida' e inverte a posição do itens dominio x arquivo -> arquivo x dominio.		
		OPT=`cat $LINK | sed 's/.*\/\///;s/\(.*\/\)/\1 /;s/\/.* / /' | \
						 sed "/\.$EXT./d" | \
						 awk '{if ($2 == "") print "Desconhecida", $1; else print; fi}' | \
						 awk '{printf "%s\n%s\n",$2,$1}' | \
						 sed "s/^$EXT$/$SEARCH.$EXT/" | \
						 yad --title="$EXT's" \
								--text="Referências encontradas: <b>$TOTAL</b>" \
								--width=700 \
								--height=600 \
								--center \
								--fixed \
								--list \
								--column='Arquivo' \
								--column='Fonte' \
								--button='Voltar!!Retorna para a janela de pesquisa.':252 \
								--button='Download!gtk-save!Iniciar download':0`
		# Código de retorno	
		RETVAL=$?

		# Extrai o valor dos campos separados pelo delimitador
		FILENAME=`echo $OPT | cut -d'|' -f1`
		FONT=`echo $OPT | cut -d'|' -f2`
		
		# Verifica o código de retorno	
		if [ $RETVAL -eq 252 ]; then
			main	# 252 Voltar
		# Se o código de retorno for '0':Download, verifica se um item foi selecionado.
		elif [ $RETVAL -eq 0 -a ! "$FILENAME" ]; then
			yad --title='Informação' \
				--text='Selecione o título desejado.' \
				--center \
				--fixed \
				--image=gtk-dialog-info \
				--button='OK':0 \
				--timeout=3 
			# Retorna para a lista
			list_file
		fi
		
		# Inicia o comando condicional 'wget' em background e aguarda o código de retorno
		if wget `grep "$FONT" $LINK | grep -m1 "$FILENAME"` --connect-timeout=5 -P "$DIR" &>$PRO; then
			# 0: Sucesso
			yad --title='Download' \
				--text="Arquivo: $FILENAME\nDownload concluído com sucesso !!!\nDeseja abrir o arquivo ?" \
				--image=gtk-ok \
				--fixed \
				--center \
				--button='Sim':0 \
				--button='Não':1
			
			# status
			RETVAL=$?
			
			[ $RETVAL -eq 0 ] && xdg-open "$DIR/$FILENAME"	# Abre o arquivo
			list_file
		else
			# 1:Falha
			yad --form \
					--title="Erro" \
					--center \
					--fixed \
					--image=gtk-dialog-error \
					--auto-kill \
					--auto-close \
					--timeout=2 \
					--button='OK':0 \
				--text='Não foi possível realizar o download do arquivo.'

			list_file	# Retorna para lista
		fi &

		# Salva o 'PID' do 'if (wget)'
		WPID=$!

		# Roda o progresso da janela de download em background enquanto o 'PID' do 'if' existir
		{ while ps -q $WPID &>/dev/null; do
			# Pega as informações da última linha do arquivo 'PRO' e imprime na janela progresso. 
			echo "# Arquivo: $FILENAME\nProgresso: `awk 'END {print $1}' $PRO`"
			sleep 0.5
		done | yad --title='Download' \
					--center \
					--fixed \
					--progress \
					--pulsate \
					--auto-close \
					--auto-kill
		
		# Mata o 'wget' se o usuário cancelar.
		} && { kill -9 `pidof wget`; } &
	
		# Grava o 'PID' do processo
		DPID=$!
	} 
	
	# Retorna
	list_file 

}

main
