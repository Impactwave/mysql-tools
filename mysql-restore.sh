#!/bin/bash

echo "-----------------------
Restore database backup
-----------------------
"
# Allow the user to override the enviroment BEFORE the common scripts are included.
# That capability requires all options to be parsed now.
while getopts "h:e:" opt; do
  case $opt in
    e)
      ENV=$OPTARG;;
    h)
      HOST="$OPTARG";;
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

if [ $# -ne 2 ]
then
  echo "Usage: $(basename $0) [options] databases archive_name

Parameters:
  databases     $MAINDB
  archive_name  The path and file name of the backup archive (a tar.gz or tgz file).

Options:
  -h hostname   Connect to MySQL on hostname / IP address; default = depends on the environment (see below).
  -e envname    Use the specified environment; default = \$ENV_NAME or 'local'.
                Environments: local|intranet|staging|production

The specified databases will be restored to the local MySQL server by default, unless overriden by the -h option or the \$ENV_NAME environment variable.
The environment name determines which configuration file will be read to obtain database connection information.
The backup archive should contain a file named '$MAINDB-dump.sql'.
"
  exit 1
fi

case $1 in
  $MAINDB)
    MAIN="$MAINDB-dump.sql"
    ;;
  *)
    echo "Invalid parameter: $1"
    exit 1
esac

case $ENV in
  local|intranet|staging|production)
    echo -e "Environment:\t$ENV";;
  *)
    echo "Invalid environment $ENV."
    exit 1
esac

get_db_login $ENV

echo -e "MySQL host:\t$HOST
Backup archive:\t$2
Temp.directory:\t$TMP_DIR
"

START=$(timer)

if [ ! -f "$2" ]
then
  echo "File $2 not found."
  exit 1
fi

echo "Extracting backup archive..."
mkdir -p "$TMP_DIR"
rm -f "$TMP_DIR/$MAINDB-dump.sql"
tar -zxf "$2" -C "$TMP_DIR"
[ $? -ne 0 ] && exit 1

if [ -n "$MAIN" ]
then
  if [ -f "$TMP_DIR/$MAIN" ]
  then
    echo "Restoring database '$MAINDB'..."
    mysql -u $MYSQL_USER -h $HOST $MAINDB < "$TMP_DIR/$MAIN"
    [ $? -ne 0 ] && exit 1
  else
    echo "$MAIN was not found."
  fi
fi

printf '\nElapsed time: %s\n\n' $(timer $START)
