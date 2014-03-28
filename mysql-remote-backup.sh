#!/bin/bash

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

echo "-----------------------------
Backup remote MySQL databases
-----------------------------
"
while getopts "h:e:t:" opt; do
  case $opt in
    t)
      TABLES="-t \"$OPTARG\""
      TABLES_STR="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
  esac
done
shift $((OPTIND-1))

if [ $# -lt 2 -o $# -gt 4 ]
then
  echo "Usage: $(basename $0) [options] databases source_env [target_folder] [archive_name]

Parameters:
  databases       $MAINDB
  source_env      local|intranet|staging|production
  target_folder   If not specified, a folder named 'backups' inside the current directory will be assumed.
  archive_name    If not specified, the backup archive will be named 'ENV-YYYY-MM-DD-hhmmss.tgz', where ENV is the remote environment name, YYYY-MM-DD is the current date and hhmmss is the current time.

Options:
  -t \"tables\"     Space-delimited list of tables to be backed up (ex: -t table1 table2).
                  You should use this option with a specific database selected.

The specified databases will be backed up from the remote MySQL server into the local machine.
The environment name determines which configuration file will be read to obtain database connection information.
The backup archive will contain a file named '$MAINDB-dump.sql'.
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

if [ $3 ]
then
  DIR=$3
else
  DIR="backups"
fi

if [ $4 ]
then
  OUT=$4
else
  OUT="$SOURCE_ENV-`date "+%Y-%m-%d-%H%M%S"`.tgz"
fi

get_ssh_login $SOURCE_ENV_CFG
SOURCE_HOST=$_HOST
SOURCE_SSH_USER=$_SSH_USER

echo -e "From:\t\t$SOURCE_HOST
Backup archive:\t$DIR/$OUT"
if [ "$TABLES" ]
then
  echo -e "Tables:\t\t$TABLES_STR"
fi
echo ""

START=$(timer)

mkdir -p $DIR

if [ $SOURCE_TYPE = "local" ]
then
  $BIN_DIR/$BACKUP_SCRIPT $TABLES -e $SOURCE_ENV $DATABASES $DIR $OUT
  [ $? -ne 0 ] && exit 1
else
  echo "Connecting to $SOURCE_SSH_USER@$SOURCE_HOST"
  ssh $SOURCE_SSH_USER@$SOURCE_HOST "cd $REMOTE_CWD; $BIN_DIR/$BACKUP_SCRIPT $TABLES -h localhost -e $SOURCE_ENV $DATABASES $TMP_DIR $ARCHIVE"
  [ $? -ne 0 ] && exit 1

  echo "Transferring backup to local computer"
  scp $SOURCE_SSH_USER@$SOURCE_HOST:$REMOTE_CWD/$TMP_DIR/$ARCHIVE $DIR/$OUT
  [ $? -ne 0 ] && exit 1
fi

echo "Database transfer completed."
printf 'Total elapsed time: %s\n\n' $(timer $START)
