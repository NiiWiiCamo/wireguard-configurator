#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# uninstaller

# set expected config version
uninstallerver=2

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

clear
echo "##########################################"
echo "#                                        #"
echo "#  WireGuard Configurator | Uninstaller  #"
echo "#                                        #"
echo "##########################################"
echo ""
echo "Welcome to the Wireguard Configurator Suite!"
echo "You have opened the uninstaller. This tool allows you to uninstall WGC and Wireguard!"
echo ""


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
  read -s -r -p "Could not find wgc-conf! Where are your configs? Default should be /etc/wireguard/ ." uninstalldir
fi

# set working dir as script dir
scriptdir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
if ! [ "${scriptdir}" -ef "${wgcdir}" ]
then
  echo "This script is not in the default location! Proceed with caution..."
  sleep 5
fi
cd ${scriptdir}


######### SYSTEM SPECIFICS ##########

runningon="debian"

# check for Raspberry PI
if grep -q "Raspberry" /proc/device-tree/model 2>/dev/null
then
  runningon="raspbian"
fi


########## CLEANING ASK ############
# ask for level or cleaning
configexport=false
echo ""
echo "What do you want to remove?"
echo "[o]nly wgc scripts and configs, I want to keep wireguard installed."
echo "[w]ireguard and all configs and scripts. Please reset my system to what it was before."
echo "[e]xport all server and client configs. Don't remove anything."
echo "[N]othing. I want to keep everything."
read -s -r -n 1 response
case ${response} in
  [oO])
    uninstall=o;;
  [wW])
    uninstall=w;;
  [eE])
    uninstall=n;configexport=true;;
  *)
    echo "Nothing will be changed. If you wanted to remove a single client config, use wgc-ungenerator.sh";exit;;
esac
unset response

echo ""
if [ ${uninstall} = "o" -o ${uninstall} = "w" ]
then
  read -s -r -n 1 -p "Do you want to export all the configs first? [Y/n]" response
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


############ CHECK FOR SYSTEM SPECIFICS ###############

# ask for raspberrypi-kernel-headers
removerkh="false"
if [ ${runningon} = "raspbian" ]
then
  echo "You are running on a Raspberry PI."
  echo ""
  read -s -r -n 1 -p "Do you want raspberry-kernel-headers to be uninstalled, too? [Y/n]" response
  echo ""
  case ${response} in
    [nN])
      removerkh="false";;
    *)
      removerkh="true";;
  esac
fi


############ LIST ALL THINGS TO BE DONE ##############
declare -a dirremove
declare -a fileremove

if [ ${defaults} ]
then
  confdir="/etc/wireguard/client-configs/"
  maindir="/etc/wireguard/"
fi

echo ""
echo ""
echo "You chose to do the following:"

if [ ${uninstall} = "o" ]
then
  dirremove=("${dirremove[@]}" "${confdir}")
  fileremove=("${fileremove[@]}" "${maindir}${wginterface}.conf")
  echo " - ${confdir} including all contents will be gone."
  echo " - Your ${wginterface}.conf will be gone."
fi

if [ ${uninstall} = "w" ]
then
  dirremove=("${dirremove[@]}" "${maindir}")
  echo ""
  echo " - Wireguard will be autoremoved."
  if [ ${removerkh} = "true" ]
  then
    echo " - RaspberryPi-Kernel-Headers will be autoremoved."
  fi
  echo " - Everything in ${maindir} will be gone. Including all configs that were not exported."
  echo " - Your apt sources will be reset."
  echo " - Your IPv4 forwarding will be disabled again."
  echo ""
fi

read -s -r -n 1 -p "Are you sure you want to commence with the actions above? [y/N]" response
echo ""
case ${response} in
  [yY])
    # uninstall everything
    if [ $uninstall = "w" ]
    then
      if [ ${removerkh} = "true" ]
      then
        apt-get -y autoremove raspberry-kernel-headers >/dev/null
        echo "Uninstalled raspberry-kernel-headers (autoremove)."
      fi
      apt-get -y autoremove wireguard >/dev/null
      echo "Uninstalled wireguard (autoremove)."
      sed -i '/unstable main$/d' /etc/apt/sources.list.d/unstable.list
      echo "Removed unstable packet sources."
      apt-key del 04EE7237B7D453EC
      echo "Removed apt key 04EE7237B7D453EC."
      sed -i '/Package: *\nPin: release a=unstable\nPin-Priority: 150\n/d' /etc/apt/preferences.d/limit-unstable
      echo "Reset apt preference for unstable list."
      sed -i '/net.ipv4.ip_forward = 1/s/^/#/g' /etc/sysctl.conf
      echo "Reset IPv4 forwarding in /etc/sysctl.conf"
    fi;

    # remove directories
    for dir in ${dirremove[@]}
    do
      rm -r ${dir} 2>/dev/null
      echo "Removed directory ${dir}."
    done;
    # remove files
    for file in ${fileremove[@]}
    do
      rm ${file} 2>/dev/null
      echo "Removed file ${file}."
    done
    ;;
  *)
    echo "";
    echo "Nothing was removed.";
    exit;;
esac
echo "Uninstaller finished. Thank you for using WireGuard Configurator!"
