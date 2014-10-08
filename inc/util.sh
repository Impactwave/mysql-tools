#!/bin/bash

#-------------------------------------------------------
# Set Laravel's relevant paths as environment variables.
# $ROOT:        public web directory.
# $APP_PATH:    application directory.
# $CONFIG_PATH: configuration directory.
# $PUBLIC_HTML: directory where index.php is located.
#
# It searches for index.php on the current folder or on
# ../public_html
# It then runs a modified index.php to extract the
# relevant configuration info.
#-------------------------------------------------------

re="\\\$app ?= ?[^']*'([^']*)"
if [ -f index.php ]; then
  index=$(cat index.php)
  PUBLIC_HTML='.'
else
  if [ -f ../public_html/index.php ]; then
    index=$(cat ../public_html/index.php)
    PUBLIC_HTML='../public_html'
  else
    echo "Can't find index.php"
    exit 1
  fi
fi
index=`echo "$index" | sed "s/\\\$app->run()/echo app_path();exit/"`
pushd . > /dev/null
cd $PUBLIC_HTML
APP_PATH=$(echo "$index" | php)
popd > /dev/null
CONFIG_PATH="$APP_PATH/config"

#---------------------------------
# Get the current environment name
#---------------------------------

# If the caller has not set ENV, set it now.
if [ -z "$ENV" ]; then
  ENV="local"
  [ $ENV_NAME ] && ENV=$ENV_NAME
fi

if [ "$ENV" == "production" ]; then
  CFG_ENV=""
else
  CFG_ENV="$ENV"
fi

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
  if [ "$1" == "production" ]; then
    _ENV=""
  else
    _ENV="$1"
  fi
  if [ -z "$HOST" ]
  then
    HOST=`awk -F\' '/'\''host'\''/{print $4;exit}' $CONFIG_PATH/$_ENV/database.php`
  fi
  MYSQL_USER=`awk -F\' '/'\''username'\''/{print $4;exit}' $CONFIG_PATH/$_ENV/database.php`
  # Export the password to be used by the mysql command:
  export MYSQL_PWD=`awk -F\' '/'\''password'\''/{print $4;exit}' $CONFIG_PATH/$_ENV/database.php`
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