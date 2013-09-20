#!/bin/bash
#########################
# X-Ray the file finder ###############
# A command line interface for 'find' #
# by joker__ <g.chers at gmail.com>   #
# Copyleft (2011)                     #
#######################################
# This script was a class project for 
# demonstrating the knowledge of find 
# Unix command, and the bash          
# programming  skills				  

# Dichiarazione delle variabili globali sulle quali sarà
# effettuata la ricerca.
 o_dir=""
o_name=""
o_date=""
o_size=""
o_user=""

# Dichiarazione delle costanti
LOGO="etc/logo"
TMP="tmp/x-ray.tmp"
cat /dev/null > $TMP # azzeramento del contenuto


# Dichiarazione delle funzioni di selezione

# Select a directory
select_dir() {
	
	[[ -nz "$o_dir" ]] && echo "Directory selezionata attualmente: $o_dir"
	
	echo "Inserire la directory in cui effettuare la ricerca"
	read o_dir
}


# Select the file's name
select_name() {
	
	[[ -nz "$o_name" ]] && echo "Nome del file selezionato attualmente: $o_name"
	
	echo "Inserire il nome del file da ricercare. (Invio per lasciare quello già impostato)"
	read o_name
	if [[ -nz "$o_name" ]]
	then
		o_name="-name $o_name"
	fi
}


# Select the file's size
select_size() {
	[[ -nz "$o_size" ]] && echo "La dimensione in bytes attualmente selezionata è: $o_size"
	
	echo "Inserire la dimensione del file da cercare in byte (aggiungere k,M,G per i moltiplicatori dei Byte):"
	echo "- \"=dimensione\" se si conosce la dimensione esatta."
	echo "- \"<>dim1 dim2\" se la dimensione del file è compresa tra dim1 e dim2."
	read -ra dim # reads and creates an array for the words separated by spaces
	
	case "${dim[@]}" in
	'='*) o_size="-size ${dim[@]#=}c";;
	'<'*) o_size="-size +${dim[0]#<>}c -and -size -${dim[1]}c";;
	*) echo "La dimensione non è stata modificata.";read;;
	esac
}


# Select the file's last change date
select_date() {
	[[ -nz "$o_date" ]] && echo "La data attualmente selezionata è: $o_date"
	
	echo "Indicare i giorni passati dall'ultima modifica del file:"
	echo "- \"giorni\": se si conosce il numero esatto di giorni."
	echo "- \"+giorni\": numero di giorni superiore a <giorni>"
	echo "- \"-giorni\": numero di giorni inferiore a <numero giorni>"
	echo "- \"<>giorni1 giorni2\": numero di giorni compreso tra giorni1 e giorni2"
	read -ra num # as for read dim in select_size
	
	case "${num[@]}" in
	'+'*) o_date="-ctime +${num[@]#+}";;
	'-'*) o_date="-ctime -${num[@]#-}";;
	'<>'*) o_date="-ctime +${num[0]#<>} -and -ctime -${num[1]}";;
	'') echo "La data non è stata modificata.";read;;
	*) o_date="-ctime ${num[@]}";;
	esac
}


# Select the file's owner
select_user() {
	[[ -nz "$o_user" ]] && echo "Utente attualmente selezionato: $o_user"
	
	echo "Inserire il nome dell'utente a cui appartiene il file"
	read o_user
	if [[ -nz "$o_user" ]]
	then
		o_user="-user $o_user"
	fi
}


# Show the already defined options
show_selected() {
	echo "Queste sono le opzioni attualmente selezionate:"
	[[ -nz "$o_dir" ]]  && echo "Directory:           $o_dir"
	[[ -nz "$o_name" ]] && echo "Nome del file:       $o_name"
	[[ -nz "$o_size" ]] && echo "Dimensione in bytes: $o_size"
	[[ -nz "$o_date" ]] && echo "Data:                $o_date"
	[[ -nz "$o_user" ]] && echo "Utente:              $o_user"
	read
}



# Inizio del programma

clear
cat $LOGO
echo
echo


# menu choices
declare -a choices
choices[1]="Seleziona la directory di ricerca"
choices[2]="Trova file per nome"
choices[3]="Trova file per data"
choices[4]="Trova file per dimensione"
choices[5]="Trova file appartenenti a un utente"
choices[6]="Visualizza le opzioni di ricerca"
choices[7]="Avvia la ricerca"
choices[8]="Esci dal programma"

r="\"Invio\" per rivedere le opzioni di ricerca"

while [[ 1 ]]
do
	select c in "Seleziona la directory di ricerca" "Trova file per nome" "Trova file per data" "Trova file per dimensione" "Trova file appartenenti a un utente" "Visualizza le opzioni di ricerca" "Avvia la ricerca" "Esci dal programma"
	do
		case "$c" in
			${choices[1]}) clear; select_dir;   clear; echo $r ;;
			${choices[2]}) clear; select_name;  clear; echo $r ;;
			${choices[3]}) clear; select_date;  clear; echo $r ;;
			${choices[4]}) clear; select_size;  clear; echo $r ;;
			${choices[5]}) clear; select_user;  clear; echo $r ;;
			${choices[6]}) clear; show_selected;clear; echo $r ;;
			${choices[7]}) clear; break;;
			${choices[8]}) clear; exit;;
		esac
	done

	[[ -z "$o_dir" ]] && o_dir="." && echo "Nessuna directory selezionata. Ricerca nella directory corrente..."
	
	# this array will contain all resultant files
	result=()
	
	
	# This will give all cases:
	# - no size nor date ( 0)
	# - size only        ( 1)
	# - date only        (10)
	# - size AND date    (11)
	c=0
	[[ -nz $o_size ]] && let c+=1
	[[ -nz $o_date ]] && let c+=10
	
	# Launch find and send output to TMP file
	case $c in
		0)  find $o_dir $o_name $o_user 2>/dev/null ;;
		1)  find $o_dir $o_name $o_user \( $o_size \) 2>/dev/null ;;
		10) find $o_dir $o_name $o_user \( $o_date \) 2>/dev/null ;;
		11) find $o_dir $o_name $o_user \( $o_size -and $o_date \) 2>/dev/null ;;
	esac > $TMP
	
	lines=$(wc -l $TMP | tr -d "[a-z/\-.' ']") # lines number into variable
	
	(( $lines == 0 )) && echo "La ricerca non ha prodotto alcun risultato."
	(( $lines != 0 )) && echo "La ricerca ha prodotto $lines risultati:" && read && cat $TMP
	
	echo "Premere \"invio\" per continuare..."
	read
	
	echo "Indicare se si vuole continuare la medesima ricerca, iniziarne una nuova, oppure uscire"
	select c in "Continua" "Nuova" "Esci"
	do
		case $c in
			"Continua") break;;
			"Nuova"   )	o_dir="";
						o_name="";
						o_date="";
						o_size="";
						o_user="";
						break;;
			"Esci"    ) exit;;
		esac
	done
	cat /dev/null > $TMP # file temporaneo ripristinato
	clear
done


