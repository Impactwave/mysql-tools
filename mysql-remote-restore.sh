#!/bin/bash

BASE=$(dirname $0)
source $BASE/inc/util.sh
source $BASE/config/config.sh

echo "--------------------------------------------
Restore database backup into a remote server
--------------------------------------------
"

if [ $# -ne 3 ]
then
  echo "Usage: $0 databases archive_name target_env

Parameters:
  databases     $MAINDB
  archive_name  The path and file name of the backup archive (a tar.gz or tgz file).
  target_env    local|intranet|staging|production

The specified backup will be restored on the target MySQL server.
The environment name determines which configuration files will be read to obtain database and SSH connection information.
"
  exit 1
fi

case $1 in
  $MAINDB)
    DATABASES=$1
    ;;
  *)
    echo "Invalid parameter: $1"
    exit 1
esac

ARCHIVE=$2
FILE=`echo $2 | rev | cut -d"/" -f1 | rev`

case $3 in
  local|intranet)
    TARGET_TYPE="local"
    TARGET_ENV=$3
    TARGET_ENV_CFG=$3
    ;;
  staging)
    TARGET_TYPE="remote"
    TARGET_ENV=$3
    TARGET_ENV_CFG=$3
    ;;
  production)
    TARGET_TYPE="remote"
    TARGET_ENV=$3
    TARGET_ENV_CFG=$3
    ;;
  *)
    echo "Invalid environment $3."
    exit 1
esac

get_ssh_login $TARGET_ENV_CFG
TARGET_HOST=$_HOST
TARGET_SSH_USER=$_SSH_USER

echo -e "From:\t$ARCHIVE"
echo -e "To:\t$TARGET_HOST
"

START=$(timer)

if [ $TARGET_TYPE = "local" ]
then
  $BIN_DIR/$RESTORE_SCRIPT -e $TARGET_ENV $DATABASES $ARCHIVE
  [ $? -ne 0 ] && exit 1
else
  echo "Transferring backup to $TARGET_SSH_USER@$TARGET_HOST"
  scp $ARCHIVE $TARGET_SSH_USER@$TARGET_HOST:$REMOTE_CWD/$TMP_DIR
  [ $? -ne 0 ] && exit 1

  echo "Connecting to $TARGET_SSH_USER@$TARGET_HOST"
  ssh $TARGET_SSH_USER@$TARGET_HOST "cd $REMOTE_CWD; $BIN_DIR/$RESTORE_SCRIPT -h localhost -e $TARGET_ENV $DATABASES $TMP_DIR/$FILE"
  [ $? -ne 0 ] && exit 1
fi

echo "Database transfer completed."
printf 'Total elapsed time: %s\n\n' $(timer $START)
