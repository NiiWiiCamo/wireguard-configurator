#!/bin/bash

# Install Script for Wireguard under Debian 10 (Buster). Add unstable packet sources, install wireguard and create a certificate. Useful in conjunction with generate-client.sh
# https://github.com/NiiWiiCamo/wireguard-configurator

# check if the script was run as root
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running this script as root! Please use sudo (or equivalent)!"
  exit 1
fi


# Getting your system up to date
apt-get update
apt-get upgrade


# check if you are running on a raspberry pi
echo "Checking if you are running on a Raspberry PI..."
if grep -q Raspberry /proc/device-tree/model
then
  echo "You are running on a Raspberry PI. Downloading an additional packet"
  apt-get install raspberry-kernel-headers
else
  echo "You are running a $(uname -o) on $(uname -r) architecture."
fi


# add unstable list
echo "deb http://deb.debian.org/debian/ unstable main" | tee --append /etc/apt/sources.list.d/unstable.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' | tee --append /etc/apt/preferences.d/limit-unstable

# update packet list again and install wireguard
apt-get update
apt-get install wireguard

# activate ipv4 forwarding in /etc/sysctl.conf
sed -i '/net.ipv4.ip_forward = 1/s/^#//g' /etc/sysctl.conf


# download generator script
curl https://raw.githubusercontent.com/NiiWiiCamo/wireguard-configurator/master/generate-client.sh --output /etc/wireguard/generate-client.sh


# change working directory
cd /etc/wireguard


umask 077

mkdir certs
mkdir client-configs

# generate server private and public keys
echo "Generating private and public keys for the server..."
wg genkey | tee certs/server-private.key | wg pubkey > certs/server-public.key

echo "You can create client certs and configs with generate-client.sh. Be sure to run those as root as well."
echo "Server needs to reboot. Reboot now?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) reboot;break;;
        No ) echo "Please reboot manually before creating any configs.";break;;
    esac
done
