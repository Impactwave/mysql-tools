#!/bin/bash

echo "-----------------------
Restore database backup
-----------------------
"
INTERACTIVE=1
ASK_PASS=

# Allow the user to override the enviroment BEFORE the common scripts are included.
# That capability requires all options to be parsed now.
while getopts "h:e:np" opt; do
  case $opt in
    e)
      ENV=$OPTARG;;
    h)
      HOST="$OPTARG";;
    n)
      INTERACTIVE=0;;
    p)
      ASK_PASS=1;;
    *)
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

MAIN="dump.sql"

if [ $# -ne 2 ]
then
  echo "Usage: $(basename $0) [options] databases archive_name

Parameters:
  databases     $MAINDB
  archive_name  The path and file name of the backup archive (a tar.gz or tgz file) or dump file (.sql).

Options:
  -h hostname   Connect to MySQL on hostname / IP address; default = depends on the environment (see below).
  -e envname    Use the specified environment; default = \$ENV_NAME or 'local'.
                Environments: local|intranet|staging|production
  -p            Ask for password.
  -n            Do not ask any interactive questions.

The specified databases will be restored to the local MySQL server by default, unless overriden by the -h option or the \$ENV_NAME environment variable.
The environment name determines which configuration file will be read to obtain database connection information.
The backup archive should contain a file named '$MAINDB-dump.sql'.
"
  exit 1
fi

case $1 in
  $MAINDB)
    # OK, valid
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

if [ $ASK_PASS ]; then
  read -sp "$MYSQL_USER's password: " MYSQL_PWD
  export MYSQL_PWD
  echo
fi

echo -e "MySQL host:\t$HOST
Database:\t$MAINDB
Backup archive:\t$2
Temp.directory:\t$TMP_DIR
"

if (($INTERACTIVE)); then
  echo "Press Enter to start or Ctrl+C to cancel..."
  read
fi

START=$(timer)

if [ ! -f "$2" ]
then
  echo "File $2 not found."
  exit 1
fi

ext=${2##*.}
if [ $ext != 'sql' ];then
  echo "Extracting backup archive..."
  mkdir -p "$TMP_DIR"
  TMP_FILE="$TMP_DIR/$MAIN"
  rm -f "$TMP_FILE"
  tar -zxf "$2" -C "$TMP_DIR"
  [ $? -ne 0 ] && exit 1
else
  echo "Using dump file $2"
  TMP_FILE="$2"
fi

if [ -f "$TMP_FILE" ]
then
  echo "Restoring database '$MAINDB'..."

  # Note: The PHP pipe script corrects ALTER DATABASE statements to target the correct database, which is important when
  # restoring backups to a database other than the one from which the backup was made.
  transform="while (feof (STDIN) === false) { \$line=fgets (STDIN);"
  transform="$transform \$line=preg_replace ('#ALTER DATABASE \`.+?\` CHARACTER SET (.+?);#', 'ALTER DATABASE \`$MAINDB\` CHARACTER SET \$1;', \$line);"
  transform="$transform echo \$line; }"

  #  mysql -u $MYSQL_USER -h $HOST $MAINDB < "$TMP_FILE"
  cat "$TMP_FILE" | php -r "$transform" | mysql -u $MYSQL_USER -h $HOST $MAINDB
  [ $? -ne 0 ] && exit 1
else
  echo "$TMP_FILE was not found."
fi

printf '\nElapsed time: %s\n\n' $(timer $START)
