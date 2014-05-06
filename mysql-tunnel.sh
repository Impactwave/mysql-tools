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

get_ssh_login staging

echo -e "\nTunneling MySQL connections to $_HOST.\nPress Ctrl+C to stop.\n"
ssh -L 3306:localhost:3306 $_SSH_USER@$_HOST -N
