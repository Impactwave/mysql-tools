#!/bin/bash

BASE=$(dirname $0)
source $BASE/inc/util.sh
source $BASE/config/config.sh

echo "--------------------------------------
Update MySQL databases between servers
--------------------------------------
"

if [ $# -ne 3 ]
then
  echo "Usage: $0 [options] databases source_env target_env

Parameters:
  databases    $MAINDB
  source_env   local|intranet|staging|production
  target_env   local|intranet|staging|production

Options:
  -t \"tables\"     Space-delimited list of tables to be backed up (ex: -t table1 table2).
                  You should use this option with a specific database selected.

The specified databases will be backed up from the source MySQL server and restored on the target MySQL server.
The environment names determine which configuration files will be read to obtain database and SSH connection information.
"
  exit 1
fi

while getopts "t:" opt; do
  case $opt in
    t)
      TABLES="-t \"$OPTARG\""
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
  esac
done
shift $((OPTIND-1))

case $1 in
  $MAINDB)
    DATABASES=$1
    ;;
  *)
    echo "Invalid parameter: $1"
    exit 1
esac

case $2 in
  local|intranet)
    SOURCE_TYPE="local"
    SOURCE_ENV=$2
    SOURCE_ENV_CFG=$2
    ;;
  staging)
    SOURCE_TYPE="remote"
    SOURCE_ENV=$2
    SOURCE_ENV_CFG=$2
    ;;
  production)
    SOURCE_TYPE="remote"
    SOURCE_ENV=$2
    SOURCE_ENV_CFG=$2
    ;;
  *)
    echo "Invalid environment $2."
    exit 1
esac

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

get_ssh_login $SOURCE_ENV_CFG
SOURCE_HOST=$_HOST
SOURCE_SSH_USER=$_SSH_USER

get_ssh_login $TARGET_ENV_CFG
TARGET_HOST=$_HOST
TARGET_SSH_USER=$_SSH_USER

echo -e "From:\t$SOURCE_HOST"
echo -e "To:\t$TARGET_HOST"

START=$(timer)

if [ $SOURCE_TYPE = "local" ]
then
  $BIN_DIR/$BACKUP_SCRIPT $TABLES -e $SOURCE_ENV $DATABASES $TMP_DIR $ARCHIVE
  [ $? -ne 0 ] && exit 1
else
  echo "Connecting to $SOURCE_SSH_USER@$SOURCE_HOST"
  ssh $SOURCE_SSH_USER@$SOURCE_HOST "cd $REMOTE_CWD; $BIN_DIR/$BACKUP_SCRIPT $TABLES -h localhost -e $SOURCE_ENV $DATABASES $TMP_DIR $ARCHIVE"
  [ $? -ne 0 ] && exit 1

  echo "Transferring backup to local computer"
  scp $SOURCE_SSH_USER@$SOURCE_HOST:$REMOTE_CWD/$TMP_DIR/$ARCHIVE $TMP_DIR
  [ $? -ne 0 ] && exit 1
fi

if [ $TARGET_TYPE = "local" ]
then
  $BIN_DIR/$RESTORE_SCRIPT -e $TARGET_ENV $DATABASES $TMP_DIR/$ARCHIVE
  [ $? -ne 0 ] && exit 1
else
  echo "Transferring backup to $TARGET_SSH_USER@$TARGET_HOST"
  scp $TMP_DIR/$ARCHIVE $TARGET_SSH_USER@$TARGET_HOST:$REMOTE_CWD/$TMP_DIR
  [ $? -ne 0 ] && exit 1

  echo "Connecting to $TARGET_SSH_USER@$TARGET_HOST"
  ssh $TARGET_SSH_USER@$TARGET_HOST "cd $REMOTE_CWD; $BIN_DIR/$RESTORE_SCRIPT -h localhost -e $TARGET_ENV $DATABASES $TMP_DIR/$ARCHIVE"
  [ $? -ne 0 ] && exit 1
fi

echo "Database transfer completed."
printf 'Total elapsed time: %s\n\n' $(timer $START)
