#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# configurator

# set expected config version
generatorver=1

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

# read wgc-config
echo "Checking config file..."
if [ -f wgc-config ]
then
  source wgc-config
else
  echo "Config file not found"
  exit 2
fi

# check config version
if ! [ ${generatorver} -eq ${configver} ]
then
  echo "Wrong config version found. Please get the current versions of the script and config. You can use wgc-update.sh for that"
  exit 2
else
  echo "Read config file with version ${configver}."
fi


# ask question with default function
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

# check for valid port function
check_port(){
  if [ -z $1 ]; then 
    return 1
  fi 
  [ "$1" -ge 1 -a "$1" -le 65535 ]
}

# check for valid ip function
check_ip(){
  if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    return 0
  else
    return 1
  fi
}


############## MAIN SCRIPT ################

# go to maindir
cd ${maindir}

# ask for interface to be configured
ask_question_with_default wginterface "Enter interface to be configured" "${wginterface}"

# Get first free ip address in defined subnet (output ${clientip})
echo "Checking for first free IP in network ${wgnetwork}0/24."
for host in {1..254}
do
	clientip=${wgnetwork}${host}
	if ! [ grep -q ${clientip} ${wginterface}.conf ]
	then
		echo "Found IP: ${clientip}"
		break
	fi
done

# check for first free assignable client name (output ${unnamedclient})
for client in {1..99}
do
	unnamedclient=${wgclientdefaultname}${client}
	if ! [ grep -q ${unnamedclient} ${wginterface}.conf ]
	then
		break
	fi
done

# ask for custom client name
# check if client name exists already
validclientname=false
while ! [ ${validclientname} ]
do
  ask_question_with_default wgclientname "What should this client be called?" "${unnamedclient}"
  if ! [ greq -q ${wgclientname} ${wginterface}.conf ]
  then
    validclientname=true
  fi
done

# get client config parameters
ask_question_with_default wgclienthostname "What address (hostname or external IP) does the client connect to?"
ask_question_with_default wgclientport "What port does the client connect to?"
ask_question_with_default wgclientdns "What DNS server shall the client use?"

# ask if config shall be copied to userhome (output ${copyconfig})
read -r -n 1 -p "Do you want the client config copied to ${wgcopydest} ? [Y/n] " response
case "$response" in
  [nN])
	  copyconfig=false;;
  *)
      copyconfig=true;;
esac
unset response

# ask for confirmation
clear
echo "Creating new client config with the following settings:"
echo "Client name       : ${wgclientname}"
echo "Client IP address : ${clientip}"
echo "Client DNS Server : ${wgclientdns}"
echo "Server hostname   : ${wgclienthostname}"
echo "Server port       : ${wgclientport}"
echo ""
if [ ${copyconfig} ]
then
  echo "Config will be copied to ${wgcopydest}"
  mkdir -p ${wgcopydest}
  cp ${confdir}${wgclientname}@${wgclienthostname}.conf ${wgcopydest}
done
echo ""
read -r -n 1 -p "Are these settings correct? [Y/n] " response
case "$response" in
  [nN])
	  echo "Nothing was written. Please restart the generator.";exit 2;;
  *)
      break;;
esac
unset response


# generate private and public keypair for the client
echo "Generating Keypair for the client..."
wg genkey | tee clientprivkey | wg pubkey clientpubkey

# create client config
cat << ENDCLIENT > ${confdir}${wgclientname}@${wgclienthostname}.conf
# Wireguard client config created with wgc-generator script version ${generatorver}
[Interface]
PrivateKey = ${clientprivkey}
Address = ${clientip}/24
DNS = ${wgclientdns}

[Peer]
PublicKey = $(cat ${certdir}server-public.key)
Endpoint = ${wgclienthostname}:${wgclientport}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
ENDCLIENT

echo "Client config generated."

# append client to server config
cat << ENDSERVER >> ${wginterface}.conf

### Start of client config for ${wgclientname} ###
[Peer]
PublicKey = ${clientpubkey}
AllowedIPs = ${clientip}/32
### End of client config for ${wgclientname} ###
ENDSERVER

echo "Added client to server config ${wginterface}."

# flush generated keys
unset clientprivkey
unset clientpubkey

# check for config export
if [ ${copyconfig} ]
then
  echo "Copying finished client config to ${wgcopydest}..."
  mkdir -p ${wgcopydest}
  cp ${confdir}${wgclientname}@${wgclienthostname}.conf ${wgcopydest}
done

echo "Finished client config is stored at ${confdir}${wgclientname}@${wgclienthostname}.conf."
