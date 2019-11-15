#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# exporter

# set expected config version
exporterver=1

# timeout for asks
timeout=20

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
if ! [ ${exporterver} -eq ${configver} ]
then
  echo "Wrong config version found. Please get the current versions of the script and config. You can use wgc-update.sh for that!"
  exit 2
else
  echo "Read config file with version ${configver}."
fi

declare -a toexport

# check for existing server config
if [ -f ${maindir}${wginterface}.conf ]
then
  echo "Found server config for ${wginterface}.conf"
  toexport+=(${maindir}${wginterface}.conf)
fi

# check for other server config files
for file in ${maindir}*
do
  if [ ${file} = *.conf ]
  then
    read -r -n 1 -p "Found additional config ${maindir}${file}.conf! Export? [Y/n]" response ":" -t ${timeout}
    case ${response}
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
  if [ ${file} -eq *.conf ]
  then
    counter++
  fi
done
read -r -n 1 -p "Found ${counter} configs in ${confdir} . Export? [Y/n]?" response -i ":" -t ${timeout}
unset counter
case ${response} in
  [nN])
    ;;
  *)
    for file in ${confdir}*
    do
      if [ ${file} -eq +.conf ]
      then
        toexport+=${confdir}${file}
      fi
    done;;
esac
unset response


# where do you want the tarball to land? (output: ${exportdir})
read -r -p "Where do you want the tarball to be placed?" exportdir -i ";" -t ${timeout}
if  [ -z ${exportdir} ]
then
  exportdir="/home/${SUDO_USER}/wireguard-export/"
fi
if ! [ -d ${exportdir} ]
then
  mkdir -p ${exportdir}
  echo "Created directory ${exportdir}."
fi

echo "Creating tarball..."
tar cf ${exportdir}wireguardexport.tar
for f in ${toexport} in
do
  tar rf ${exportdir}wireguardexport.tar ${f}
done

# ask for filetree export
read -r -n 1 -p "Do you want to export as filetree in addition to tarball? [Y/n]" response -i ";" -t ${timeout}
case ${response} in
  [nN])
    ;;
  *)
    echo "Copying files to ${exportdir}..."
    for f in ${toexport}
    do
      cp ${f} ${exportdir}
    done
    ;;
esac
