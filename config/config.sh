#!/bin/bash

# Scripts folder path (relative to the project folder)
BIN_DIR="vendor/impactwave/mysql-tools"

# Temporary folder path (relative to the project folder)
TMP_DIR="tmp"

BACKUP_SCRIPT="mysql-backup.sh"

RESTORE_SCRIPT="mysql-restore.sh"

# Default file name of backup archives for remote operations via SSH
ARCHIVE="mysql-dump.tgz"

# Get main database name from the configuration file for the current environment
MAINDB=`awk -F\' '/'\''database'\''/{print $4;exit}' $CONFIG_PATH/$ENV/database.php`
