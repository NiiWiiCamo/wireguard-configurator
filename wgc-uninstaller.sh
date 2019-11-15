#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# uninstaller

# set expected config version
uninstallerver=1

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
  # check config version
  if ! [ ${installerver} -eq ${configver} ]
  then
    echo "Wrong config version found. Proceeding with default cleaning."
  else
    echo "Read config file with version ${configver}."
  fi
else if [ -f /etc/wireguard/wgc-config ]
then
  uninstalldir=/etc/wireguard/
else
  echo "Config file not found"
  read -r -p "Could not find wgc-conf! Where are your configs? Default should be /etc/wireguard/ ." uninstalldir
fi

read -r -n 1 -p "What do you want to remove?\n [o]nly wgc scripts and configs, I want to keep wireguard installed.\n[w]ireguard and all configs and scripts. Please reset my system to what it was before.\n[e]xport all server and client configs. Don't remove anything.\n[N]othing. I want to keep everything." response
case ${response} in
  [oO])
    uninstall=o;break;;
  [wW])
    uninstall=w;break;;
  [eE])
    uninstall=n;configexport=true;break;;
  [*])
    echo "Nothing will be changed. If you wanted to remove a single client config, use wgc-ungenerator.sh";exit;;
esac
unset response

if [ ${uninstall} -eq o -o ${uninstall} -eq w ]
then
  read -r -n 1 -p "Do you want to export all the configs first? [Y/n]" response
  case ${response} in
    [nN])
      configexport=false;break;;
    *)
      configexport=true;break;;
  esac
fi
unset response

