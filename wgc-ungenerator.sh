#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# ungenerator

# set expected config version
ungeneratorver=2

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

clear
echo "##########################################"
echo "#                                        #"
echo "#  WireGuard Configurator | Ungenerator  #"
echo "#                                        #"
echo "##########################################"
echo ""
echo "Welcome to the Wireguard Configurator Suite!"
echo "You have opened the ungenerator. This tool will remove existing client configs from your server config!"
echo ""

# set working dir as script dir
scriptdir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# read wgc-config
echo "Checking config file..."
if [ -f wgc-config ]
then
  source wgc-config
else
  echo "Config file not found"
  exit 2
fi

# check for default location
if ! [ "${scriptdir}" -ef "${wgcdir}" ]
then
  echo "This script is not in the default location! Proceed with caution..."
  sleep 5
fi
cd ${scriptdir}


# check config version
if ! [ ${ungeneratorver} -eq ${configver} ]
then
  echo "Wrong config version found. Please get the current versions of the script and config. You can use wgc-update.sh for that"
  exit 2
else
  echo "Read config file with version ${configver}."
fi

######### MAIN SCRIPT #########

# go to maindir
cd ${maindir}

# check for default config
if [ -f ${wginterface}.conf ]
then
  echo "Found ${wginterface}.conf!"
else
  echo "Did not find ${wginterface}.conf. Please check wgc-config if the correct interface is entered."
  exit 2
fi


# check existing client configs according to server config
echo "Checking for configured clients in ${wginterface}.conf..."
declare -a clients
IFS="
"
for line in $(grep '^#\*#' ${maindir}${wginterface}.conf)
do
#  echo -n "line:"
#  echo "${line}"
  client=${line#\#\*\#*for }
#  echo ${client}
  client=${client::-4}
#  echo "Found ${client}"
  clients+=("${client}")
done


#declare -p clients
#echo "Clients: ${clients[*]}"

echo "Found ${#clients[@]} configured in ${wginterface}.conf:"

#i=0
#for client in ${clients[@]}
#do
#  ((i++))
#  echo "${i} : ${client}"
#done

#nrclient=${#clients[*]}
#for (( i=0; i<=$(( ${nrclient} -1 )); i++ ))
#do
#  echo "${i}: ${clients[${i}]}"
#done

echo "Select the number you want to remove:"
select response in "${clients[*]}"
do
  break
done <<< 1

read -s -r remclient
do
  if [ "${remclient}" -le "${#clients[*]}" ]
  then
    break
  fi
done

echo "Selected ${response}..."
