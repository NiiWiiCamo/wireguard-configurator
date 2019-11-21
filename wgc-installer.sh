#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# installer

# set expected config version
installerver=3

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

clear
echo "########################################"
echo "#                                      #"
echo "#  WireGuard Configurator | Installer  #"
echo "#                                      #"
echo "########################################"
echo ""
echo "Welcome to the Wireguard Configurator Suite!"
echo "You have opened the installer. This tool will install wireguard and setup your system!"
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
if ! [ ${installerver} -eq ${configver} ]
then
  echo "Wrong config version found. Please get the current versions of the script and config. You can use wgc-update.sh for that!"
  exit 2
else
  echo "Read config file with version ${configver}."
fi

if ! [ "${scriptdir}" -ef "${wgcdir}" ]
then
  echo "This script is not in the default location! Proceed with caution..."
  sleep ${sleeptimer}
fi
cd ${scriptdir}


###################### ASK ############
echo ""
echo "This script will install wireguard and setup your system."
echo ""
echo "The following actions will be performed:"
echo " - Updating and Upgrading your system (apt-get)"
echo " - If you are on a Raspberry Pi: Installing raspberry-kernel-headers"
echo " - Adding the unstable packet sources and giving them a low priority"
echo " - Updating the packet lists again"
echo " - Installing WireGuard"
echo " - Activating IPv4 forwarding in your /etc/sysctl.conf"
echo ""
echo "After that this script will set up the WGC environment according to the wgc-config:"
echo " - Creation of directories in ${maindir}"
echo " - Generation of server keys and the main server config"
echo ""
echo "Do you want to start the installation? [Y/n]"
echo ""
read -s -r -n 1 result
case ${result} in
  [nN])
    echo "The installation was aborted. Please restart the script to install.";
    exit;;
  *)
    echo "Commencing with installation..."
esac


######### INSTALLATION ###########

# update and upgrade
echo "Updating packet list and upgrading packets..."
apt-get update &>/dev/null
apt-get -q -y upgrade &>/dev/null

# check for Raspberry PI
echo "Checking if you are running on a Raspberry PI..."
if grep -q Raspberry /proc/device-tree/model &>/dev/null
then
  echo "You are running on a Raspberry PI. Downloading an additional packet..."
  apt-get -q -y install raspberry-kernel-headers &>/dev/null
else
  echo "You are running a $(uname -o) on $(uname -r) architechture."
fi

# add unstable list with low priority
echo "deb http://deb.debian.org/debian/ unstable main" >> /etc/apt/sources.list.d/unstable.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC &>/dev/null
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' >> /etc/apt/preferences.d/limit-unstable

# update and install wireguard
echo "Updating packet list and installing wireguard..."
apt-get update &>/dev/null
apt-get -q -y install wireguard &>/dev/null

# activate ipv4 forwarding in /etc/sysctl.conf
sed -i '/net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf

# goto maindir and create subdirs
echo "Creating subdirectories..."
cd ${maindir}
mkdir -p ${confdir}
mkdir -p ${certdir}

# generate server private and public keys
echo "Generating server private and public keypair..."
srvprivkey=$(wg genkey)
srvpubkey=$(echo ${srvprivkey} | wg pubkey)
echo ${srvpubkey} > ${certdir}server-public.key

# create interface config
echo "Generating ${wginterface}.conf..."
cat << ENDINTERFACE > ${wginterface}.conf
#################
# Server config #
#################
[Interface]
Address = ${wgnetwork}${wgserverip}/24
ListenPort = ${wgserverport}
PrivateKey = ${srvprivkey}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true

#############################
# Client configs below here #
#############################

ENDINTERFACE

# flush generated keys
unset srvprivkey
unset srvpubkey

# check if wgc-generator is present, if not ask for download
if [ -f ${wgcdir}/wgc-generator.sh ]
then
  echo "You can generate client configs with ${wgcdir}wgc-generator.sh"
else
  echo "WGC-Generator script not found. Start wgc-downloader.sh now? [Y/n]"
  read -s -r -n 1 response
  case "$response" in
    [nN])
      ;;
    *)
      source ${wgcdir}wgc-downloader.sh
      ;;
esac
fi
unset response

echo "The server should be rebooted after the installation. Reboot now? [y/N]"
read -s -r -n 1 response
case "$response" in
  [yY])
    echo "Rebooting now...";
    reboot now;;
  *)
    echo "Please reboot manually later.";;
esac
unset response


echo "Do you want to start WGC Master? [Y/n]"
read -s -r -n 1 response
case "$response" in
  [nN])
    echo "Thank you for using WireGuard Configurator!";
    exit;;
  *)
    ${wgcdir}wgc-master.sh;;
esac
unset response
