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

_env=staging
if [[ $1 != '' ]]; then
  _env=$1
fi
get_ssh_login $_env

echo -e "\nTunneling MySQL connections to $_HOST.\nPress Ctrl+C to stop.\n"
ssh -L 3306:localhost:3306 $_SSH_USER@$_HOST -N
