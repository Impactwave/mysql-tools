#!/bin/bash

#-------------------------------------------------------
# Set Laravel's relevant paths as environment variables.
# $ROOT:        public web directory.
# $APP_PATH:    application directory.
# $CONFIG_PATH: configuration directory.
#
# It searches for index.php on the current folder or on
# ../public_html
# It then runs a modified index.php to extract the
# relevant configuration info.
#-------------------------------------------------------

# The APP_DIR environment variable is optional and allows you to specify where to look for the Laravel app. relative to the project's root directory
re="\\\$app ?= ?[^']*'([^']*)"
if [ -d config ]; then
  APP_PATH="`pwd`"
else
  if [ -d "$APP_DIR/config" ]; then
    APP_PATH="`pwd`/$APP_DIR"
  else
    echo "Can't find the config directory. Tip: set the APP_DIR env. variable to a relative path from your current working directory."
    exit 1
  fi
fi

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
  if [ "$HOST" == "DB_HOST" ]; then
    HOST=$DB_HOST
  fi
  if [ "$MYSQL_USER" == "DB_USERNAME" ]; then
    MYSQL_USER=$DB_USERNAME
  fi
  if [ "$MYSQL_PWD" == "DB_HOST" ]; then
    export MYSQL_PWD=$DB_PASSWORD
  fi
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
  _SSH_PORT=`awk -F\' '/'\''SSH_port'\''/{print $3;exit}' $CONFIG_PATH/$_ENV/settings.php`
  _SSH_PORT=$(echo $_SSH_PORT | tr -dc '0-9')
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
