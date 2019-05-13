#!/bin/bash
IP="192.168.1.50"

let "PORT=1234"
let "PORT2=1235"
let "PORT_RECV=1236"
let "PORT_SEND=1237"
let "PORTID=1238"
let "PORTCL=1239"

########################### Faire tableau de clients connectés
all_port="all_port.txt"
file_clport="cl_port.txt"
id_sh="nathan_id.sh"
msg_to_send=""
filename="recv.txt"
IP_temp="cl_ip.txt"
IP_allowed="ip_allowed.txt"
HOSTS="hosts.txt"
recv="recv_all.txt"
msg_remove=""

function clean() # On nettoie les fichiers temporaire à chaque redemarrages
{
	rm $IP_allowed
	rm $HOSTS
	rm $filename
	rm $IP_temp
	rm $recv
	rm $file_clport
	rm $all_port
}

function ID()
{
	local user=""
	local ID_done=""
	local IP=""
	while [ 1 -eq 1 ];do
		echo "ID Running"
		echo "$PORTCL" > $file_clport

		ncat -l -p $PORT --recv-only > $filename # LOCAL IP ADRESS
		IP=`cat $filename`
		echo "Client Ip : $IP"
		echo "$IP" > $IP_temp
		ncat -l -p $PORT -e $id_sh ## Identification Nathan 
		## ON IDENTIFIE L'IP ET ON ENVOIE SI L'ID S'EST BIEN DEROULE OU PAS
		for i in `cat $HOSTS`;do
			if [ "$i" = "$IP" ];then
				echo "User logged in host.txt"
				line=`cat $HOSTS | tail -1`
				IFS=" " read -a array <<< "$line"
				user=${array[1]} # ON recupere le deuxieme : user
				echo "OK $user $PORTCL" |ncat -l -p $PORTID --send-only # Si il y a l'IP dans HOSTS ALORS OK
				let "PORTCL=$PORTCL+1"

				ID_done="OK"
				sleep 0.5
				msg_to_send="server There are actually `cat $HOSTS |wc -l` clients connected"
				SEND &
				msg_to_send="server $user has joined the channel"
				SEND &
			fi			
		done
		if [ "$ID_done" != "OK" ];then
			echo "NO"|ncat -l -p $PORTID --send-only # Sinon --> NO
		fi	
		sleep 0.1
	done
}
function SEND()
{
	for port in `cat $all_port`;do
		echo "Send with : $port"
		echo "$msg_to_send" |ncat -l -p $port -w 1
	done	
function remove_client()
{
	local host_temp="tmp.txt"	
	echo "User : $1 is disconnected"
	echo "Removing client ..."

	if [ `cat $HOSTS |wc -l` = "1" ];then
		echo "Just one client was connected ..."
		rm $HOSTS
		touch $HOSTS
		echo "Done"
	else
		echo "Removing $1 ..."	
		sed /$1/'d' $HOSTS > $host_temp
		cat $host_temp > $HOSTS
		rm $host_temp

#		IFS=" " read -a host_array <<< `cat $HOSTS`
#		for info in ${!host_array[@]};do
#			if [ $info = $user ];then
#				let "line=info/2"
#				echo "Line : $line"
#				sed $line'd' $IP_allowed > $host_temp
#				`cat $host_temp` > $IP_allowed
#				rm $host_temp
#				echo "Done IP IP_allowed" 
#			fi
#		done		
	fi


	echo "Done"
	msg_to_send="server $1 is disconnected"
	SEND&	
}
function RECV()
{
	while [ 1 -eq 1 ];
	do
		ncat -l -p $PORT_RECV --recv-only > $recv

		msg=`cat $recv`

		IFS=" " read -a msg_array <<< "$msg"

		if [ "$msg" != "" ];then # Si non vide
			echo -e "Recu : $msg" # SI EXIT --> on supprime de hosts.txt
			echo -e "[1] : ${msg_array[1]}"
			if [ "${msg_array[1]}" = "exit" ];then
				msg_remove=$msg
				remove_client ${msg_array[0]}
			else		
				msg_to_send=$msg
				SEND 
			fi
		fi
		sleep 0.1

	done
}

function main()
{
	clean ## On clean les hosts de la session precedente
	touch $HOSTS
	touch $IP_allowed
	clear
	echo "Server opened at :  $IP:$PORT"

	ID &
	pid1=$!

	
	RECV &
	pid2=$!

	trap '{ echo "[!] Ctrl-c pressed closing threads $pid1 $pid2 and cleaning up .."; kill $pid1;kill $pid2; echo "Done";clean; exit 1;}' INT


	while [ 1 -eq 1 ];do
		#clear
		echo -e "Hotes connectées :\n`cat $HOSTS`"
		sleep 3
	done	

	wait $pid1 && echo "pid1 exited normally" || echo "pid1 exited abnormally with status $?"
	wait $pid2 && echo "pid2 exited normally" || echo "pid2 exited abnormally with status $?"

}

main


























































#wait $pid1 && echo "pid1 exited normally" || echo "pid1 exited abnormally with status $?"

#wait # On attend que les threads finissent

#ncat -k -l 1234 

# UN NCAT POUR ENVOYER ET UN AUTRE POUR RECEVOIR

#connection
#mkfifo backpipe
#nc -k -l 12345 < backpipe | cat 1> backpipe


#ncat --keep-open --listen -p $PORT | send_all

#connection | ncat --keep-open --listen -p $PORT 
#ncat -l --chat -p $PORT
##./server.sh | `nc -l -p $PORT` 
#  -c, --sh-exec <command>    Executes the given command via /bin/sh
#  -e, --exec <command>       Executes the given command
# https://www.systutorials.com/docs/linux/man/1-ncat/
#https://doc.fedora-fr.org/wiki/Netcat,_connexion_client/serveur_en_bash
