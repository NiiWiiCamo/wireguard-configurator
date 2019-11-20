#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# generator

# set expected config version
generatorver=3

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

clear
echo "########################################"
echo "#                                      #"
echo "#  WireGuard Configurator | Generator  #"
echo "#                                      #"
echo "########################################"
echo ""
echo "Welcome to the Wireguard Configurator Suite!"
echo "You have opened the generator. This tool will generate client configs ready to use!"
echo ""

# read wgc-config
echo "Checking config file..."
if [ -f wgc-config ]
then
  source wgc-config
else
  echo "Config file not found"
  exit 2
fi

# set working dir as script dir
scriptdir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
if ! [ "${scriptdir}" -ef "${wgcdir}" ]
then
  echo "This script is not in the default location! Proceed with caution..."
  sleep ${sleeptimer}
fi
cd ${scriptdir}


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

if [ -f "${wginterface}.conf" ]
then
  echo "Found ${wginterface}.conf!"
else
  echo "Could not find ${wginterface}.conf!"
  echo "Please check if wireguard is installed with wgc-installer.sh!"
  exit 2
fi

# Get first free ip address in defined subnet (output ${clientip})
echo "Checking for first free IP in network ${wgnetwork}0/24."
for host in {1..254}
do
  clientip=${wgnetwork}${host}
  if ! grep -q "${clientip}" "${wginterface}.conf"
  then
    echo "Found IP: ${clientip}"
    break
  fi
done

# check for first free assignable client name (output ${unnamedclient})
echo "Checking existing client names..."
for client in {1..99}
do
  unnamedclient=${wgclientdefaultname}${client}
  if ! grep -q "${unnamedclient}" "${wginterface}.conf"
  then
    echo "Found free name ${unnamedclient}!"
    break
  fi
done

# ask for custom client name
# check if client name exists already
while true
do
  ask_question_with_default wgclientname "What should this client be called?" ${unnamedclient}
  if grep -q "${wgclientname}" "${wginterface}.conf"
  then
    echo "This client already exists. Please choose a different name."
  else
    break
  fi
done

# get client config parameters
ask_question_with_default wgclienthostname "What address (hostname or external IP) does the client connect to?" ${wgclienthostname}
ask_question_with_default wgclientport "What port does the client connect to?" ${wgclientport}
ask_question_with_default wgclientdns "What DNS server shall the client use?" ${wgclientdns}

# ask if config shall be copied to userhome (output ${copyconfig})
echo "Do you want the client config copied to ${wgcopydest} ? [Y/n]"
read -s -r -n 1 response
case "$response" in
  [nN])
    copyconfig=false;;
  *)
    copyconfig=true;;
esac

# ask for confirmation
clear
echo "### NEW CLIENT CONFIGURATION ###"
echo ""
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
fi
echo "Are these settings correct? [Y/n]"
read -s -r -n 1 response
case ${response} in
  [nN])
    echo "Nothing was written. Please restart the generator.";exit 2;;
  *)
    echo "Commencing...";;
esac


# generate private and public keypair for the client
echo "Generating Keypair for the client..."
wg genkey | tee ${wgclientname}-priv.key | wg pubkey > ${wgclientname}-pub.key
clientprivkey=$(cat ${wgclientname}-priv.key)
echo "${clientprivkey}"
clientpubkey=$(cat ${wgclientname}-pub.key)
echo "${clientpubkey}"
echo "Do you want to keep the generated certificates? This is only necessary if you want to recreate the config at a later date. [y/N]"
read -s -r -n 1 result
case $result in
  [yY])
    echo "Saving Keypair for ${wgclientname} to ${maindir}${certdir}...";
    mv ${wgclientname}-priv.key ${certdir};
    mv ${wgclientname}-pub.key ${certdir};;
  *)
    echo "Removing Keypair...";
    rm ${wgclientname}-priv.key;
    rm ${wgclientname}-pub.key;
    echo "If you remove the client config from ${confdir}, you will not be able to restore it!";;
esac

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
#*# Start of client config for ${wgclientname} ###
[Peer]
PublicKey = ${clientpubkey}
AllowedIPs = ${clientip}/32
### End of client config for ${wgclientname} #*#
ENDSERVER

echo "Added client to server config ${wginterface}."

# flush generated keys
unset clientprivkey
unset clientpubkey

echo "Finished client config is stored at ${confdir}${wgclientname}@${wgclienthostname}.conf."

# check for config export
if [ ${copyconfig} ]
then
  echo "Copying finished client config to ${wgcopydest}..."
  mkdir -p ${wgcopydest}
  cp ${confdir}${wgclientname}@${wgclienthostname}.conf ${wgcopydest}
  chown -R ${SUDO_USER} ${wgcopydest}
fi

echo ""
echo "Generator finished. Thank you for using WireGuard Configurator!"
echo ""
echo "Do you want to check all currently allowed clients? [Y/n]"
read -s -r -n 1 result
case ${result} in
  [nN])
    echo "You can do that at a later date with wgc-ungenerator.sh!";;
  *)
    echo "Starting wgc-ungenerator.sh...";
    source ${wgcdir}wgc-ungenerator.sh;;
esac

