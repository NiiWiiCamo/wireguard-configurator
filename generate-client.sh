#!/bin/bash

# WireGuard Certificate and Config generator

# Parameters (Change here pls)


interface=wg0			# wireguard interface to configure, default: wg0
workingdir=/etc/wireguard/	# working directory default: /etc/wireguard
network="10.255.255."		# first three network octets (currently only /24 supported), default: 10.255.255.
dns=				# dns server that the clients will use, default is empty (will be asked on execution)
hostname=			# hostname the clients will connect to, usually external, default is empty (will be asked on execution)
serverport=51820		# server port for external clients
copydest=/home/pi/		# destination for config files to be copied to (for scp access)
user=pi				# user to own the copied config afterwards


# Script, pls don't change much here:

if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running this script as root! Please use sudo (or equivalent)!"
  exit 1
fi

cd $workingdir

echo -n "Enter client name: "
read client
wg genkey | tee certs/$client-private.key | wg pubkey > certs/$client-public.key

# Check for a free IP address for the client

echo "Checking for first free IP in network ${network}0/24."

for host in {1..200}
do
  address=$network$host
#  echo $address
  if ! grep -q $address $interface.conf
  then
    echo "Found IP: "$address
    break
  fi
done

if test -z "$interface"
then
  echo -n "Enter interface to be configured: "
  read interface
fi

if test -z "$dns"
then
  echo -n "Enter DNS address: "
  read dns
fi

if test -z "$hostname"
then
  echo -n "Enter public server address: "
  read hostname
fi

if test -z "$serverport"
then
  echo -n "Enter external server port: "
  read serverport
fi



cat << ENDCLIENT > client-configs/$client.conf
[Interface]
Privatekey = $(cat certs/$client-private.key)
Address = $address
DNS = $dns

[Peer]
PublicKey = $(cat certs/server-public.key)
Endpoint = $hostname:$serverport
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
ENDCLIENT

cat << ENDSERVER >> $interface.conf
# Client config $client
[Peer]
PublicKey = $(cat certs/$client-public.key)
AllowedIPs = $address/32
ENDSERVER

echo "Copying config to $copydest$client.conf and giving user $user ownership"
cp /etc/wireguard/client-configs/$client.conf $copydest$client.conf
chown $user $copydest$client.conf


echo "Do you wish to restart Wireguard interface $interface now?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) wg-quick down $interface;wg-quick up $interface;echo "$interface was restarted!";break;;
        No ) echo "Please restart $interface manually to reload the config";break;;
    esac
done
