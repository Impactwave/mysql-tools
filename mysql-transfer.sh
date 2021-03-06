#!/bin/bash

echo "----------------------------------------
Transfer MySQL databases between servers
----------------------------------------
"
N_FLAG=''

#Note: options must be extracted now, otherwise they'll be lost.
while getopts "t:n" opt; do
  case $opt in
    t)
      TABLES="-t \"$OPTARG\""
      ;;
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

if [ $# -ne 4 ]
then
  echo "Usage: $(basename $0) [options] source_database target_database source_env target_env

Parameters:
  source_database A database name.
  target_database A database name.
  source_env      local|intranet|staging|production
  target_env      local|intranet|staging|production

Options:
  -t \"tables\"     Space-delimited list of tables to be backed up (ex: -t table1 table2).
                  You should use this option with a specific database selected.
  -n              Do not ask any interactive questions.

The specified database will be backed up from the source MySQL server and restored on the target MySQL server on the specified database.
The environment names determine which configuration files will be read to obtain database and SSH connection information.
"
  exit 1
fi

SRC_DATABASE=$1
TARGET_DATABASE=$2

case $3 in
  local|intranet)
    SOURCE_TYPE="local"
    ;;
  staging|production)
    SOURCE_TYPE="remote"
    ;;
  *)
    echo "Invalid environment $3."
    exit 1
esac
SOURCE_ENV=$3

case $4 in
  local|intranet)
    TARGET_TYPE="local"
    ;;
  staging|production)
    TARGET_TYPE="remote"
    ;;
  *)
    echo "Invalid environment $4."
    exit 1
esac
TARGET_ENV=$4

get_ssh_login $SOURCE_ENV
SOURCE_HOST=$_HOST
SOURCE_SSH_USER=$_SSH_USER
SOURCE_SSH_PORT=$_SSH_PORT

get_ssh_login $TARGET_ENV
TARGET_HOST=$_HOST
TARGET_SSH_USER=$_SSH_USER
TARGET_SSH_PORT=$_SSH_PORT

echo -e "From:\t$SOURCE_HOST"
echo -e "To:\t$TARGET_HOST"

if [ -z "$N_FLAG" ]; then
  read -p "Press Enter to start or Ctrl+C to cancel..."
  echo
fi

START=$(timer)

if [ $SOURCE_TYPE = "local" ]
then
  $BIN_DIR/$BACKUP_SCRIPT $TABLES -e $SOURCE_ENV $N_FLAG $SRC_DATABASE $TMP_DIR $ARCHIVE
  [ $? -ne 0 ] && exit 1
else
  get_remote_cwd $SOURCE_ENV

  echo "Connecting to $SOURCE_SSH_USER@$SOURCE_HOST"
  ssh $SOURCE_SSH_USER@$SOURCE_HOST -p $SOURCE_SSH_PORT "cd $REMOTE_CWD; $BIN_DIR/$BACKUP_SCRIPT $TABLES -h localhost -e $SOURCE_ENV $N_FLAG $SRC_DATABASE $TMP_DIR $ARCHIVE"
  [ $? -ne 0 ] && exit 1

  echo "Transferring backup to local computer"
  scp -P $SOURCE_SSH_PORT $SOURCE_SSH_USER@$SOURCE_HOST:$REMOTE_CWD/$TMP_DIR/$ARCHIVE $TMP_DIR
  [ $? -ne 0 ] && exit 1
fi

if [ $TARGET_TYPE = "local" ]
then
  $BIN_DIR/$RESTORE_SCRIPT -e $TARGET_ENV $N_FLAG $TARGET_DATABASE $TMP_DIR/$ARCHIVE
  [ $? -ne 0 ] && exit 1
else
  get_remote_cwd $TARGET_ENV

  echo "Transferring backup to $TARGET_SSH_USER@$TARGET_HOST"
  ssh $TARGET_SSH_USER@$TARGET_HOST -p $TARGET_SSH_PORT "mkdir -p $REMOTE_CWD/$TMP_DIR" # create the target directory if it doesn't exist
  scp -P $TARGET_SSH_PORT $TMP_DIR/$ARCHIVE $TARGET_SSH_USER@$TARGET_HOST:$REMOTE_CWD/$TMP_DIR
  [ $? -ne 0 ] && exit 1

  echo "Connecting to $TARGET_SSH_USER@$TARGET_HOST"
  ssh $TARGET_SSH_USER@$TARGET_HOST -p $TARGET_SSH_PORT "cd $REMOTE_CWD; $BIN_DIR/$RESTORE_SCRIPT -h localhost -e $TARGET_ENV $N_FLAG $TARGET_DATABASE $TMP_DIR/$ARCHIVE"
  [ $? -ne 0 ] && exit 1
fi

echo "Database transfer completed."
printf 'Total elapsed time: %s\n\n' $(timer $START)
