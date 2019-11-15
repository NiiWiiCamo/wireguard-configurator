#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# installer

# set expected config version
installerver=1

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
if ! [ ${installerver} -eq ${configver} ]
then
  echo "Wrong config version found. Please get the current versions of the script and config. You can use wgc-update.sh for that!"
  exit 2
else
  echo "Read config file with version ${configver}."
fi

# update and upgrade
echo "Updating packet list and upgrading packets..."
apt-get update >/dev/null
apt-get -q -y upgrade

# check for Raspberry PI
echo "Checking if you are running on a Raspberry PI..."
if grep -q Raspberry /proc/device-tree/model
then
  echo "You are running on a Raspberry PI. Downloading an additional packet..."
  apt-get -q -y install raspberry-kernel-headers
else
  echo "You are running a $(uname -o) on $(uname -r) architechture."
fi

# add unstable list with low priority
echo "deb http://deb.debian.org/debian/ unstable main" | tee --append /etc/apt/sources.list.d/unstable.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' | tee --append /etc/apt/preferences.d/limit-unstable

# update and install wireguard
echo "Updating packet list and installing wireguard..."
apt-get update >/dev/null
apt-get -q -y install wireguard

# activate ipv4 forwarding in /etc/sysctl.conf
sed -i '/net.ipv4.ip_forward = 1/s/^#//g' /etc/sysctl.conf

# goto maindir and create subdirs
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
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A F$
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D$
SaveConfig = true

#############################
# Client configs below here #
#############################

ENDINTERFACE

# flush generated keys
unset srvprivkey
unset srvpubkey

# check if wgc-generator is present, if not ask for download
if [ -f wgc-generator.sh ]
then
  echo "You can generate client configs with ${maindir}wgc-generator.sh"
else
  read -r -n 1 -p "WGC-Generator script not found. Do you want to download it now? [Y/n] " response
  case "$response" in
    [nN])
      break;;
    *)
      wget -O ${maindir}wgc-generator.sh ${giturl}wgc-generator.sh 2>/dev/null || curl ${giturl}wgc-generator.sh --output ${maindir}wgc-generator.sh 2>/dev/null || echo "Please install either wget or curl, or download it manually from ${giturl}wgc-generator.sh";;
esac
fi
unset response


read -r -n 1 -p "The server should be rebooted after the installation. Reboot now? [Y/n] " response
case "$response" in
  [nN])
    echo "Please reboot manually later.";;
  *)
    echo "Rebooting now...";
    reboot now;;
esac
unset response
