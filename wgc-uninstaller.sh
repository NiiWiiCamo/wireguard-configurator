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
    defaults=true
  else
    echo "Read config file with version ${configver}."
  fi
else if [ -f /etc/wireguard/wgc-config ]
then
  uninstalldir=/etc/wireguard/
else
  echo "Config file not found"
  read -r -p "Could not find wgc-conf! Where are your configs? Default should be /etc/wireguard/ .`\n" uninstalldir
fi

read -r -n 1 -p "What do you want to remove?`\n [o]nly wgc scripts and configs, I want to keep wireguard installed.`\n[w]ireguard and all configs and scripts. Please reset my system to what it was before.`\n[e]xport all server and client configs. Don't remove anything.`\n[N]othing. I want to keep everything.`\n" response
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
  read -r -n 1 -p "Do you want to export all the configs first? [Y/n]`\n" response
  case ${response} in
    [nN])
      configexport=false;break;;
    *)
      configexport=true;break;;
  esac
fi
unset response

# config exporter
if [ ${configexport} ]
then
  clear
  echo "Starting wgc-exporter.sh..."
  source wgc-exporter.sh
fi


############ LIST ALL THINGS TO BE DONE ##############
declare -a dirremove
declare -a fileremove
clear
if [ ${defaults} ]
then
  confdir="/etc/wireguard/client-configs/"
  maindir="/etc/wireguard/"
fi

echo "You chose to do the following:`\n"

if [ ${uninstall} -eq o ]
then
  ${dirremove}+="${confdir}"
  ${fileremove}+="${maindir}${wginterface}.conf"
  echo " - ${confdir} including all contents will be gone.`\n - Your ${wginterface}.conf will be gone.`\n"
fi

if [ ${uninstall} -eq w ]
  ${dirremove}+="${maindir}"
  echo " - Wireguard will be autoremoved.`\n - Everything in ${maindir} will be gone. Including all configs that were not exported.`\n - Your apt sources will be reset.`\n - Your IPv4 forwarding will be disabled again.`\n"
fi

read -r -n 1 -p "Are you sure you want to commence with the actions above? [y/N]`\n" response
case ${response} in
  [yY])
    for dir in ${dirremove}
    do
      rm -r ${dir}
      echo "Removed directory ${dir}.`\n"
    done;
    for file in ${fileremove}
    do
      rm ${file}
      echo "Removed file ${file}.`\n"
    done;
    if [ $uninstall -eq w ]
    then
      apt-get -y autoremove wireguard >/dev/null
      sed -z -i 'deb http://deb.debian.org/debian/ unstable main' /etc/apt/sources.list.d/unstable.list
      apt-key delete 04EE7237B7D453EC
      sed -z -i 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' /etc/apt/preferences.d/limit-unstable
      sed -i '/net.ipv4.ip_forward = 1/s/^/#/g' /etc/sysctl.conf
    fi;;
  *)
    echo "Nothing was removed.";
    exit;;
esac
echo "Script finished. Thank you, come again!"
