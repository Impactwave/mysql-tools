#!/bin/bash

CONFIG_PATH="src/config"

#---------------------------------
# Get the current environment name
#---------------------------------

ENV="local"
[ $ENV_NAME ] && ENV=$ENV_NAME
OENV=$ENV

while getopts "h:e:t:" opt; do
  case $opt in
    e)
      ENV=$OPTARG
      OENV=$OPTARG
      ;;
  esac
done

#---------------------------------

timer()
{
  if [[ $# -eq 0 ]]; then
    echo $(date '+%s')
  else
    local  stime=$1
    etime=$(date '+%s')
    if [[ -z "$stime" ]]; then stime=$etime; fi
    dt=$((etime - stime))
    ds=$((dt % 60))
    dm=$(((dt / 60) % 60))
    dh=$((dt / 3600))
    printf '%d:%02d:%02d' $dh $dm $ds
  fi
}

get_db_login()
{
  if [ -z "$HOST" ]
  then
    HOST=`awk -F\' '/'\''host'\''/{print $4;exit}' $CONFIG_PATH/$ENV/database.php`
  fi
  MYSQL_USER=`awk -F\' '/'\''username'\''/{print $4;exit}' $CONFIG_PATH/$ENV/database.php`
  # Export the password to be used by the mysql command:
  export MYSQL_PWD=`awk -F\' '/'\''password'\''/{print $4;exit}' $CONFIG_PATH/$ENV/database.php`
}

get_ssh_login()
{
  if [ "$1" == "production" ]; then
    _ENV=""
  else
    _ENV="$1"
  fi
  _HOST=`awk -F\' '/'\''MySQL_host'\''/{print $4;exit}' $CONFIG_PATH/$_ENV/settings.php`
  _SSH_USER=`awk -F\' '/'\''SSH_user'\''/{print $4;exit}' $CONFIG_PATH/$_ENV/settings.php`
}

get_remote_cwd()
{
  if [ "$1" == "production" ]; then
    _ENV=""
  else
    _ENV="$1"
  fi
  # Project folder path on remote server (relative to the SSH user's home folder)
  REMOTE_CWD=`awk -F\' '/'\''remote_cwd'\''/{print $4;exit}' $CONFIG_PATH/$_ENV/settings.php`
}