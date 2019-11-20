##!/bin/bash

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

########## CREATE LIST OF EXISTING CLIENTS ##############

# create an array of all client names
echo "Checking for configured clients in ${wginterface}.conf..."
declare -a clients
IFS="
"
for line in $(grep '^# Start' ${maindir}${wginterface}.conf)
do
  client=${line#\#\ Start-*}
  clients+=("${client}")
done

# if no clients are configured, quit
if [ ${#clients[@]} -eq 0 ]
then
  echo "No clients are configured in ${wginterface}.conf!"
  echo "Quitting..."
  exit
fi

echo ""
echo "Found ${#clients[@]} configured in ${wginterface}.conf:"

# print client array with user friendly naming scheme (starting at 1)
for (( i=0; i<$(( ${#clients[*]} )); i++ ))
do
  number=$((${i}+1))
  echo "${number}: ${clients[${i}]}"
done
unset number

# aks which client shall be removed

response=0 # default input
tries=0 # counter for invalid inputs
maxtries=5 #abort after x fails
while [ -z ${response} -o ${response} -le 0 -o ${response} -gt ${#clients[@]} ]
do
  echo ""
  echo "Please select one of the numbers above, or press q to cancel."
  read -s -r -n 1 response
  # check for quit condition
  if [ "${response}" = "q" -o "${tries}" -ge "${maxtries}" ]
  then
    echo "Thank you for using WireGuard Configurator!"
    echo "Quitting..."
    exit
  fi
  # add a counter for failed tries
  tries=$((${tries}+1))
done
unset tries
unset maxtries

number=$((${response}-1)) # array index of actual client.
unset response
client=${clients[$number]}
configs="${confdir}""${client}""@*"
echo "Selected ${client}."
echo "Checking for client configs..."

rmconfig="true"
if [ -f ${configs} ]
then
  echo "Found config for ${client}. Do you want to remove it as well? [Y/n]"
  read -s -r -n 1 response
  case ${response} in
    [nN])
      echo "Keeping client config. If you generate a new config for the same client name, this will be overwritten!";
      rmconfig="false";;
    *)
      ;;
  esac
else
  echo "Did not find client configs."
fi

########## LIST WHAT WILL BE DONE ############

echo "###########"
echo "This script will do the following:"
echo " - Create a backup of your ${wginterface}.conf"
echo " - Modify your ${wginterface}.conf to remove the textblock corresponding with ${client}."
if [ "${rmconfig}" = "true" ]
then
  echo " - Remove your client config from ${confdir}."
fi

########## ASK FOR CONFIRMATION ############

echo ""
echo "Are you sure you want to commence with the actions listed above? [y/N]"
read -s -r -n 1 response
case ${response} in
  [yY])
    echo "Ungenerating ${client}...";
    echo "Creating backup of ${wginterface}.conf...";
    cp ${maindir}${wginterface}.conf ${maindir}${wginterface}.conf.backup;
    firstline="\#\ Start-${client}";
    lastline="\#\ End-${client}";
    #echo $firstline
    #echo $lastline
    echo "Ungenerating ${client} from ${wginterface}.conf...";
    sed '/# Start-${client}/d' ${maindir}${wginterface}.conf;
    if [ "${rmconfig}" = "true" ]
    then
      echo "Removing config file..."
      rm ${configs}
    fi;
    echo "";
    echo "Ungeneration finished. Thank you for using WireGuard Configurator!";
    ;;
  *)
    echo "Aborting Ungenerator. Thank you for using WireGuard Configurator!";
    ;;
esac
echo "Quitting..."
exit
echo "### You have reached the current end of the file. ###"
