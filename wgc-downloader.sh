#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# downloader

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

# set git base URL, needs branch added
giturl="https://raw.githubusercontent.com/NiiWiiCamo/wireguard-configurator/"
gitbranch="indev"
# set default paths
wgcdir="/etc/wireguard/wgc"
wgcbackupdir="/etc/wireguard/wgc_backup"
# make an array of all current files
wgcfiles=("README.md" "wgc-config" "wgc-downloader.sh" "wgc-exporter.sh" "wgc-generator.sh" "wgc-installer.sh" "wgc-ungenerator.sh" "wgc-uninstaller.sh")


clear
echo "#########################################"
echo "#                                       #"
echo "#  WireGuard Configurator | Downloader  #"
echo "#                                       #"
echo "#########################################"
echo ""
echo "Welcome to the Wireguard Configurator Suite!"
echo "You have opened the downloader. This tool will get all the other scripts from GitHub!"
echo ""
echo "The default directory is ${wgcdir}."

# check for previous install of wgc
if [ -d ${wgcdir} ]
then
  echo "WGC is already present. I will create a backup at ${wgcbackupdir}."
  # check for existing backup
  if [ -d ${wgcbackupdir} ]
  then
    echo "Previous backup found. Overwrite? [Y/n]"
    read -r -n 1 result
    case ${result} in
      [nN])
        echo "Please move your backup manually and restart this script.";
        exit;;
      *)
        echo "Removing old backup...";
        rm -r ${wgcbackupdir};;
    esac
    unset result
  fi
  # create backup
  echo "Creating backup..."
  mv ${wgcdir} ${wgcbackupdir}
  echo "Your existing WGC files are now at ${wgcbackupdir}"
  echo ""
fi

###### download current version from github
# ask for branch
echo "WGC will be downloaded from GitHub now."
#read gitbranch
#if [ -z ${gitbranch} ]
#then
#  gitbranch=${defaultbranch}
#fi
echo "You have selected branch ${gitbranch} for your download. Commencing..."
giturl="${giturl}${gitbranch}/"
mkdir -p ${wgcdir}
cd ${wgcdir}
# do the actual download stuff
for file in ${wgcfiles[@]}
do
  echo "Downloading ${file}..."
  curl -O ${giturl}${file} 2>/dev/null || wget ${giturl}${file} 2>/dev/null || echo "Either the file is missing, or you have neither cUrl nor wget installed. Please install one of those for this script."
  if [[ ${file} = *.sh ]]
  then
    chmod +x ${file}
  fi
done
echo ""
echo "Finished downloading. You can now use wgc-master.sh (TBD) or any of the other scripts to get going!"

# check if wireguard is installed already
echo ""
if apt -qq list wireguard 2>/dev/null | grep -q wireguard ;
then
  echo "Wireguard is already installed. If you are looking to reinstall, please use wgc-uninstaller.sh!"
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
echo ""
echo "Thank you for using WGC - WireGuard Configurator!"
