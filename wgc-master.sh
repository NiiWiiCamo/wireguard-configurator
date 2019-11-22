#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# master

# set expected config version
masterver=3

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

clear
echo "#####################################"
echo "#                                   #"
echo "#  WireGuard Configurator | Master  #"
echo "#                                   #"
echo "#####################################"
echo ""
echo "Welcome to the Wireguard Configurator Suite!"
echo "You have opened the master script. This tool will help you use all the other scripts!"
echo ""

# set working dir as script dir
scriptdir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd ${scriptdir}

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
if ! [ ${masterver} -eq ${configver} ]
then
  echo "Wrong config version found. Please get the current versions of the script and config. You can use wgc-download.sh for that"
  exit 2
else
  echo "Read config file with version ${configver}."
fi

# check if script was is at maindir
if ! [ "${scriptdir}" -ef "${wgcdir}" ]
then
  echo ""
  echo "This script is not in the default location! Proceed with caution..."
  sleep ${sleeptimer}
fi
cd ${scriptdir}


##### CHECK FOR EXISTING SCRIPTS #####
echo ""
echo "You currently have the following scripts installed:"
pathlength=${#wgcdir}
for script in ${wgcdir}wgc-*.sh
do
  scriptname=${script:${#wgcdir}}
  echo " - ${scriptname}"
done

# check if wireguard is installed already
echo ""
if apt -qq list wireguard 2>/dev/null | grep -q wireguard ;
then
  echo -n "Wireguard is already installed"
  if systemctl is-active --quiet wireguard
  then
    echo " and currently running."
  else
  echo " but currently stopped."
  fi
else
  echo "Wireguard is not installed yet, do you want to start the install script now? [Y/n]"
  read -s -r -n 1 response
  case ${response} in
    [nN])
      echo "You can use wgc-installer.sh or wgc-master.sh (TBD) to manually start the installation.";;
    *)
      echo "Starting wgc-installer.sh...";
      source wgc-installer.sh;;
  esac
  unset response
fi

####### CHECK FOR CONFIGURED CLIENTS

# create an array of all client names
echo ""
echo "Checking for configured clients in ${wginterface}.conf..."
declare -a clients
IFS="
"
for line in $(grep '^#\*#' ${maindir}${wginterface}.conf)
do
#  client=${line#\#\ Start-*}
  client=${line#\#\*\#*for }
  client=${client::-4}
  clients+=("${client}")
done

# if no clients are configured, quit
echo ""
if [ ${#clients[@]} -eq 0 ]
then
  echo "No clients are configured in ${wginterface}.conf!"
else
  echo "Found ${#clients[@]} configured in ${wginterface}.conf:"
  # print client array with user friendly naming scheme (starting at 1)
  for (( i=0; i<$(( ${#clients[*]} )); i++ ))
  do
    number=$((${i}+1))
    echo "${number}: ${clients[${i}]}"
  done
  unset number
fi


###### ASK WHAT SHOULD BE DONE

response=0 # default input
tries=0 # counter for invalid inputs
maxtries=5 #abort after x fails
while [[ ${response} != [q12345] ]]
do
  clear
  echo "### WireGuard Configurator ###"
  echo "There are ${#clients[@]} currently configured in ${wginterface}.conf."
  echo ""
  echo "You can do the following:"
  echo "1) Generate a new client config"
  echo "2) Ungenerate an existing client config"
  echo "3) Uninstall WGC or WGC and WireGuard"
  echo "4) Export existing configs"
  echo "5) Update WGC and WireGuard"
  echo "q) Quit"
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

case ${response} in
  1)
    echo "Starting WGC Generator...";
    ${wgcdir}wgc-generator.sh;
    exit;;
  2)
    echo "Starting WGC Ungenerator...";
    ${wgcdir}wgc-ungenerator.sh;
    exit;;
  3)
    echo "Starting WGC Uninstaller...";
    ${wgcdir}wgc-uninstaller.sh;
    exit;;
  4)
    echo "Starting WGC Exporter...";
    ${wgcdir}wgc-exporter.sh;
    exit;;
  5)
    echo "Starting WGC Updater...";
    ${wgcdir}wgc-updater.sh;
    exit;;
esac
