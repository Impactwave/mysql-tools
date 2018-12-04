#!/bin/bash

echo "--------------------------------------------
Restore database backup into a remote server
--------------------------------------------
"
N_FLAG=''

#Note: options must be extracted now, otherwise they'll be lost.
while getopts "n" opt; do
  case $opt in
    n)
      N_FLAG='-n';;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
  esac
done
shift $((OPTIND-1))

OBASE=$(pwd)
cd $(dirname $0)
LNK=$(readlink $(basename $0)) # Check if path is a symlink
if [ -n "$LNK" ]; then
  cd $(dirname $LNK)
fi
BASE=$(pwd -P)
cd $OBASE

source $BASE/inc/util.sh
source $BASE/config/config.sh

if [ $# -ne 3 ]
then
  echo "Usage: $(basename $0) databases archive_name target_env

Parameters:
  databases     $MAINDB
  archive_name  The path and file name of the backup archive (a tar.gz or tgz file).
  target_env    local|intranet|staging|production

Options:
  -n            Do not ask any interactive questions.

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
    ;;
  staging|production)
    TARGET_TYPE="remote"
    ;;
  *)
    echo "Invalid environment $3."
    exit 1
esac
TARGET_ENV=$3

get_ssh_login $TARGET_ENV
TARGET_HOST=$_HOST
TARGET_SSH_USER=$_SSH_USER
TARGET_SSH_PORT=$_SSH_PORT

get_remote_cwd $TARGET_ENV

echo -e "From:\t$ARCHIVE"
echo -e "To:\t$TARGET_HOST
"

if [ -z "$N_FLAG" ]; then
  echo "Press Enter to start or Ctrl+C to cancel..."
  read
fi

START=$(timer)

if [ $TARGET_TYPE = "local" ]
then
  $BIN_DIR/$RESTORE_SCRIPT -e $TARGET_ENV $N_FLAG $DATABASES $ARCHIVE
  [ $? -ne 0 ] && exit 1
else
  echo "Transferring backup to $TARGET_SSH_USER@$TARGET_HOST"
  ssh $TARGET_SSH_USER@$TARGET_HOST -p $TARGET_SSH_PORT "mkdir -p $REMOTE_CWD/$TMP_DIR" # create the target directory if it doesn't exist
  scp -P $TARGET_SSH_PORT $ARCHIVE $TARGET_SSH_USER@$TARGET_HOST:$REMOTE_CWD/$TMP_DIR
  [ $? -ne 0 ] && exit 1

  echo "Connecting to $TARGET_SSH_USER@$TARGET_HOST"
  ssh $TARGET_SSH_USER@$TARGET_HOST -p $TARGET_SSH_PORT "cd $REMOTE_CWD; $BIN_DIR/$RESTORE_SCRIPT -h localhost -e $TARGET_ENV $N_FLAG $DATABASES $TMP_DIR/$FILE"
  [ $? -ne 0 ] && exit 1
fi

echo "Database transfer completed."
printf 'Total elapsed time: %s\n\n' $(timer $START)
