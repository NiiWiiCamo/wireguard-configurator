#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# exporter

# set expected config version
exporterver=3

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

clear
echo "#######################################"
echo "#                                     #"
echo "#  WireGuard Configurator | Exporter  #"
echo "#                                     #"
echo "#######################################"
echo ""
echo "Welcome to the Wireguard Configurator Suite!"
echo "You have opened the exporter. This tool can export all your WGC configs!"
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
if ! [ ${exporterver} -eq ${configver} ]
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


###############################

declare -a toexport

# check for existing server config
echo "Checking for ${wginterface} server config..."
if [ -f ${maindir}${wginterface}.conf ]
then
  echo "Found server config for ${wginterface}.conf"
  toexport+=(${maindir}${wginterface}.conf)
else
  echo "Didn't find specified server config!"
fi

# check for other server config files
for file in ${maindir}*
do
  if [ ${file} = *.conf ]
  then
    echo "Found additional config ${maindir}${file}.conf! Export? [Y/n]"
    echo ""
    read -s -r -n 1 response
    case ${response} in
      [nN])
        break;;
      *)
        toexport+=(${maindir}${file});break;;
    esac
  fi
  unset response
done


# check client configs
echo "Checking for client configs in ${confdir}..."
counter=0
for file in ${confdir}*
do
  if [ ${file} = *.conf ]
  then
    counter++
  fi
done
echo "Found ${counter} configs in ${confdir}. Export? [Y/n]?"
read -s -r -n 1 response
unset counter
case ${response} in
  [nN])
    ;;
  *)
    for file in ${confdir}*
    do
      if [ ${file} = *.conf ]
      then
        toexport+=${confdir}${file}
      fi
    done;;
esac
unset response


# check if anything will be exported
if [ ${#toexport[@]} = 0 ]
then
  echo "Nothing found to export! Please check the directories manually!"
  exit
fi

# where do you want the tarball to land? (output: ${exportdir})
exportdirdefault="/home/${SUDO_USER}/wireguard-export/"
echo "Where do you want the tarball to be placed? [${exportdirdefault}]"
read -s -r -n 1 exportdir
if  [ -z ${exportdir} ]
then
  exportdir=${exportdirdefault}
fi
if ! [ -d ${exportdir} ]
then
  mkdir -p ${exportdir}
  echo "Created directory ${exportdir}"
fi

echo "Creating tarball..."
echo "Wireguard Config Export created by wgc-export.sh on $(date)." > wgcexport.txt
echo "Exported files:" >> wgcexport.txt
tar cf ${exportdir}wgcexport.tar wgcexport.txt
for f in ${toexport[@]} in
do
#  echo ${f} >> wgcexport.txt
  tar rf ${exportdir}wgcexport.tar ${f}
done
echo "Tarball finished. You can find it at ${exportdir}wgcexport.tar"

# ask for filetree export
echo "Do you want to export as filetree in addition to tarball? [Y/n]"
read -s -r -n 1 response
case ${response} in
  [nN])
    ;;
  *)
    echo "Copying files to ${exportdir}...";
    for f in ${toexport[@]}
    do
      cp ${f} ${exportdir}
    done;
    ;;
esac
chown -R ${SUDO_USER} ${exportdir}
rm wgcexport.txt
echo "Export finished. Exiting..."
