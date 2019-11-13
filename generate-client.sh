#!/bin/bash

# WireGuard Certificate and Config generator


ask_question_with_default(){
  # 1. arg out val
  # 2. arg is Text
  # 3. arg is default value
  # 4. arg (optional) validator function
  # return is the result
  local valid_input=0
  read $1 <<< "$3"
  if [ $# -eq 4 ]; then
    local validator=$4
    local has_validator=1
  else
    local has_validator=0
  fi
  while true; do 
    echo -n "$2 [$3]: "
    read tmp
    if [ -z $tmp ]; then
      read $1 <<< "$3"
      read tmp <<< "$3"
    else
      read $1 <<< "$tmp"
    fi
    if [ $has_validator -eq 1 ]; then
      $validator "$tmp"
      local RC=$?
      if [ $RC -eq 0 ]; then
        return 0
      fi
    else
      return 0
    fi
  done
}

check_port(){
  if [ -z $1 ]; then 
    return 1
  fi 
  [ "$1" -ge 1 -a "$1" -le 65535 ]
}

check_ip(){
  if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    return 0
  else
    return 1
  fi
}

interface=${WG_INTERFACE:-wg0}          # wireguard interface to configure, default: wg0
ask_question_with_default	interface	"Enter interface to be configured" 	"${interface}"	

workingdir=${WG_PWD:-/etc/wireguard}              # working directory default: auto=scriptdir
network=${WG_NETWORK:-10.255.255.}      # first three network octets (currently only /24 supported), default: 10.255.255.


# Script, pls don't change much here:
if [ X${workingdir} = Xauto ]; then
  cd $(dirname $(readlink -f $0))
  workingdir=$PWD
fi

if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running this script as root! Please use sudo (or equivalent)!"
  #exit 1
fi

cd $workingdir

echo -n "Enter client name: "
read client
wg genkey | tee certs/${client}-private.key | wg pubkey > certs/${client}-public.key

# Check for a free IP address for the client

echo "Checking for first free IP in network ${network}0/24."

for host in {1..200}
do
  address=${network}${host}
#  echo $address
  if ! grep -q ${address} ${interface}.conf
  then
    echo "Found IP: "${address}
    break
  fi
done


# Parameters (Change here pls)

dns=${WG_DNS:-1.1.1.1}                  # dns server that the clients will use, default is empty (will be asked on execution)
ask_question_with_default	dns		"Enter DNS address" 			"${dns}" 	

hostname=${WG_HOSTNAME:-$(hostname)}    # hostname the clients will connect to, usually external, default is empty (will be ask$
ask_question_with_default	hostname	"Enter public server address" 		"${hostname}"	

serverport=${WG_PORT:-51820}            # server port for external clients
ask_question_with_default	serverport	"Enter external server port" 		"${serverport}"	check_port

user=${WG_USER:-pi}                     # user to own the copied config afterwards
ask_question_with_default	user		"Enter user to give config to."		"${user}"	

copydest=${WG_PATH:-/home/$user}/	# destination for config files to be copied to (for scp access)
ask_question_with_default	copydest	"Where shall the config be copied to?"	"${copydest}"	


cat << ENDCLIENT > client-configs/${client}@${hostname}.conf
[Interface]
Privatekey = $(cat certs/${client}-private.key)
Address = ${address}
DNS = ${dns}

[Peer]
PublicKey = $(cat certs/server-public.key)
Endpoint = ${hostname}:${serverport}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
ENDCLIENT

cat << ENDSERVER >> ${interface}.conf
# Client config ${client}
[Peer]
PublicKey = $(cat certs/${client}-public.key)
AllowedIPs = ${address}/32
ENDSERVER

echo "Copying config to ${copydest}${client}@${hostname}.conf and giving user ${user} ownership"
cp ${workingdir}/client-configs/${client}@${hostname}.conf ${copydest}${client}@${hostname}.conf
chown $user ${copydest}${client}@${hostname}.conf

echo "Do you want to clean up the generated certificates? If you lose your config you will not be able to restore it!"
select yn in "Yes" "No"; do
  case $yn in
    Yes ) rm ${workingdir}/certs/${client}-public.key ${workingdir}/certs/${client}-private.key;break;;
    No ) echo "Keeping files...";break;;
  esac
done

echo "Do you wish to restart Wireguard interface ${interface} now?"
select yn in "Yes" "No"; do
  case $yn in
    Yes ) wg-quick down ${interface};wg-quick up ${interface};echo "${interface} was restarted!";break;;
    No ) echo "Please restart ${interface} manually to reload the config";break;;
  esac
done
