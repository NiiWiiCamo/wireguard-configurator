#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# configurator

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
  echo "Wrong config version found. Please get the current versions of the script and config. You can use wgc-update.sh for tha$
  exit 2
else
  echo "Read config file with version ${configver}."
fi


# ask question with default function
ask_question_with_default(){
  # 1. arg out val
  # 2. arg is Text
  # 3. arg is default value
  # 4. arg (optional) validator function
  # return is the result
  local valid_input=0
  read $1 <<< "$3"
  if [ $# -eq 4 ]; then
    local validator=$4
    local has_validator=1
  else
    local has_validator=0
  fi
  while true; do 
    echo -n "$2 [$3]: "
    read tmp
    if [ -z $tmp ]; then
      read $1 <<< "$3"
      read tmp <<< "$3"
    else
      read $1 <<< "$tmp"
    fi
    if [ $has_validator -eq 1 ]; then
      $validator "$tmp"
      local RC=$?
      if [ $RC -eq 0 ]; then
        return 0
      fi
    else
      return 0
    fi
  done
}

# check for valid port function
check_port(){
  if [ -z $1 ]; then 
    return 1
  fi 
  [ "$1" -ge 1 -a "$1" -le 65535 ]
}

# check for valid ip function
check_ip(){
  if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    return 0
  else
    return 1
  fi
}

# Get first free ip address in defined subnet



ask_question_with_default 

# ask for interface to be configured
ask_question_with_default interface "Enter interface to be configured" "${wginterface}"

