#!/bin/bash

echo "----------------------
Backup MySQL databases
----------------------
"
INTERACTIVE=1

# Allow the user to override the enviroment BEFORE the common scripts are included.
# That capability requires all options to be parsed now.
while getopts "h:e:t:n" opt; do
  case $opt in
    e)
      ENV=$OPTARG;;
    h)
      HOST="$OPTARG";;
    t)
      TABLES="--tables $OPTARG"
      TABLES_STR="$OPTARG"
      ;;
    n)
      INTERACTIVE=0;;
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

BACKUP_OTIONS="--compress --create-options --routines --extended-insert --quick --single-transaction --skip-dump-date"
MYSQL_5_6_OPTIONS=" --set-gtid-purged=OFF"
MAIN="dump.sql"

if [ $# -lt 1 -o $# -gt 3 ]
then
  echo "Usage: $(basename $0) [options] databases [target_folder] [archive_name]

Parameters:
  databases       $MAINDB
  target_folder   If not specified, a folder named 'backups' inside the current directory will be assumed.
  archive_name    If not specified, the backup archive will be named 'ENV-YYYY-MM-DD-hhmmss.tgz', where ENV is the remote environment name, YYYY-MM-DD is the current date and hhmmss is the current time.

Options:
  -h hostname     Connect to MySQL on hostname / IP address; default = depends on the environment (see below).
  -e envname      Use the specified environment; default = \$ENV_NAME or 'local'.
                  Environments: local|intranet|staging|production
  -t \"tables\"     Space-delimited list of tables to be backed up (ex: -t table1 table2).
                  You should use this option with a specific database selected.
  -n              Do not ask any interactive questions.

The specified databases will be backed up from the local MySQL server by default, unless overriden by the -h option or the \$ENV_NAME environment variable.
The environment name determines which configuration file will be read to obtain database connection information.
The backup archive will contain a file named 'dump.sql'.
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

if [ "$2" ]
then
  DIR="$2"
else
  DIR="backups"
fi

if [ "$3" ]
then
  OUT="$3"
else
  OUT="$ENV-`date "+%Y-%m-%d-%H%M%S"`.tgz"
fi

echo -e "MySQL host:\t$HOST
Database:\t$MAINDB
Backup archive:\t$DIR/$OUT
Temp.directory:\t$TMP_DIR"
if [ "$TABLES" ]
then
  echo -e "Tables:\t\t$TABLES_STR"
fi
echo

if (($INTERACTIVE)); then
  echo "Press Enter to start or Ctrl+C to cancel..."
  read
fi

START=$(timer)

# Detect MySQL version; if >= 5.6, append extra options.
ver=`mysqldump -u $MYSQL_USER -h $HOST --version`
[[ $ver =~ Distrib\ 5\.([0-9]+) ]]
ver=${BASH_REMATCH[1]}
[ -z "$ver" ] && echo "MySQL v5.x was not found." && exit 1
[ "$ver" -gt 5 ] && BACKUP_OTIONS="$BACKUP_OTIONS $MYSQL_5_6_OPTIONS"

echo "Dumping database '$MAINDB'..."
mkdir -p "$TMP_DIR"
# Note: The PHP pipe script removes 'DEFINER=xxx' SQL statements to prevent the 'you need (at least one of) the SUPER privilege(s) for this operation' error.
mysqldump -u $MYSQL_USER -h $HOST $BACKUP_OTIONS $MAINDB $TABLES | php -r "while (feof (STDIN) === false) echo preg_replace ('#DEFINER=[^\s\*]+#', '', fgets (STDIN));" > "$TMP_DIR/$MAIN"

[ $? -ne 0 ] && exit 1

echo "Generating backup file..."
mkdir -p "$DIR"
tar -zcf "$DIR/$OUT" -C "$TMP_DIR" $MAIN

printf '\nElapsed time: %s\n\n' $(timer $START)
