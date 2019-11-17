#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# exporter

# set expected config version
exporterver=1

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

# set working dir as script dir
cd "${0%/*}"

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




###############################

declare -a toexport

# check for existing server config
echo -e "Checking for ${wginterface} server config..."
if [ -f ${maindir}${wginterface}.conf ]
then
  echo -e "Found server config for ${wginterface}.conf\n"
  toexport+=(${maindir}${wginterface}.conf)
else
  echo -e "Didn't find specified server config!\n"
fi

# check for other server config files
for file in ${maindir}*
do
  if [ ${file} = *.conf ]
  then
    read -r -n 1 -p "Found additional config ${maindir}${file}.conf! Export? [Y/n]" response
    echo ""
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
echo -e "Checking for client configs in ${confdir}...\n"
counter=0
for file in ${confdir}*
do
  if [ ${file} = *.conf ]
  then
    counter++
  fi
done
read -r -n 1 -p "Found ${counter} configs in ${confdir} . Export? [Y/n]?" response
echo ""
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
  echo -e "Nothing found to export! Please check the directories manually!\n"
  exit
fi

# where do you want the tarball to land? (output: ${exportdir})
exportdirdefault="/home/${SUDO_USER}/wireguard-export/"
read -r -p "Where do you want the tarball to be placed? [${exportdirdefault}]" exportdir
echo ""
if  [ -z ${exportdir} ]
then
  exportdir=${exportdirdefault}
fi
if ! [ -d ${exportdir} ]
then
  mkdir -p ${exportdir}
  echo -e "Created directory ${exportdir}.\n"
fi

echo -e "Creating tarball...\n"
echo "Wireguard Config Export created by wgc-export.sh on $(date)." > wgexport.txt
tar cf ${exportdir}wgexport.tar wgexport.txt
rm wgexport.txt
for f in ${toexport[@]} in
do
  tar rf ${exportdir}wgexport.tar ${f}
done
echo -e "Tarball finished. You can find it at ${exportdir}wgcexport.tar"

# ask for filetree export
read -r -n 1 -p "Do you want to export as filetree in addition to tarball? [Y/n]" response
echo ""
case ${response} in
  [nN])
    ;;
  *)
    echo -e "Copying files to ${exportdir}...\n";
    for f in ${toexport[@]}
    do
      cp ${f} ${exportdir}
    done;
    ;;
esac
chown -R ${SUDO_USER} ${exportdir}
echo -e "Export finished. Exiting..."
