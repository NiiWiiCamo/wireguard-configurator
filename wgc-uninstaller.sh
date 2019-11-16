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
  if ! [ ${uninstallerver} -eq ${configver} ]
  then
    echo "Wrong config version found. Proceeding with default cleaning."
    defaults=true
  else
    echo "Read config file with version ${configver}."
  fi
elif [ -f /etc/wireguard/wgc-config ]
then
  echo "Found config at /etc/wireguard/wgc-config."
  uninstalldir=/etc/wireguard/
else
  echo "Config file not found"
  read -r -p "Could not find wgc-conf! Where are your configs? Default should be /etc/wireguard/ ." uninstalldir
fi

configexport=false

# ask for level or cleaning
echo -e "\nWhat do you want to remove? \n[o]nly wgc scripts and configs, I want to keep wireguard installed.\n[w]ireguard and all configs and scripts. Please reset my system to what it was before.\n[e]xport all server and client configs. Don't remove anything.\n[N]othing. I want to keep everything."
read -r -n 1 response
case ${response} in
  [oO])
    uninstall=o;;
  [wW])
    uninstall=w;;
  [eE])
    uninstall=n;configexport=true;;
  [*])
    echo "Nothing will be changed. If you wanted to remove a single client config, use wgc-ungenerator.sh";exit;;
esac
unset response

echo "\n"
if [ ${uninstall} = "o" -o ${uninstall} = "w" ]
then
  read -r -n 1 -p "Do you want to export all the configs first? [Y/n]" response
  case ${response} in
    [nN])
      configexport=false;;
    *)
      configexport=true;;
  esac
fi
unset response

# config exporter
if [ ${configexport} = true ]
then
  echo "Starting wgc-exporter.sh..."
  source wgc-exporter.sh
fi


############ LIST ALL THINGS TO BE DONE ##############
declare -a dirremove
declare -a fileremove

if [ ${defaults} ]
then
  confdir="/etc/wireguard/client-configs/"
  maindir="/etc/wireguard/"
fi

echo -e "\nYou chose to do the following:"

if [ ${uninstall} = "o" ]
then
  dirremove=("${dirremove[@]}" "${confdir}")
  fileremove=("${fileremove[@]}" "${maindir}${wginterface}.conf")
  echo -e "\n - ${confdir} including all contents will be gone.\n - Your ${wginterface}.conf will be gone."
fi

if [ ${uninstall} = "w" ]
then
  dirremove=("${dirremove[@]}" "${maindir}")
  echo -e "\n - Wireguard will be autoremoved.\n - Everything in ${maindir} will be gone. Including all configs that were not exported.\n - Your apt sources will be reset.\n - Your IPv4 forwarding will be disabled again.\n"
fi

read -r -n 1 -p "Are you sure you want to commence with the actions above? [y/N]" response
echo -e "\n"
case ${response} in
  [yY])
    for dir in ${dirremove[@]}
    do
      rm -r ${dir} 2>/dev/null
      echo -e "\nRemoved directory ${dir}."
    done;

    for file in ${fileremove[@]}
    do
      rm ${file} 2>/dev/null
      echo -e "\nRemoved file ${file}."
    done;

    if [ $uninstall = "w" ]
    then
      apt-get -y autoremove wireguard >/dev/null
      echo -e "\n Uninstalled wireguard (autoremove)."
      sed -z -i '/unstable main$/d' /etc/apt/sources.list.d/unstable.list
      echo -e "\nRemoved unstable packet sources."
      apt-key del 04EE7237B7D453EC
      echo -e "\nRemoved apt key 04EE7237B7D453EC."
      sed -z -i '/Package: *\nPin: release a=unstable\nPin-Priority: 150\n/d' /etc/apt/preferences.d/limit-unstable
      echo -e "\nReset apt preference for unstable list."
      sed -i '/net.ipv4.ip_forward = 1/s/^/#/g' /etc/sysctl.conf
      echo -e "\nReset IPv4 forwarding in /etc/sysctl.conf"
    fi
    ;;
  [*])
    echo -e "\nNothing was removed.\n";
    exit;;
esac
echo -e "Script finished.\nPress any key or wait 10 seconds to exit."
read -t 10 -n 1
