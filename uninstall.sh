#!/bin/bash
#uninstaller script

#set working dir
DIR_ROOT=$(dirname -- "$0")
cd "$DIR_ROOT" || exit 1

#load external lib
source shell_modules/shell-lib/autoload.sh

log.warning "Make sure to run this script with sudo"

{
    uninstall_binary "db"
    uninstall_manpage "db-cli.1.gz"
} || log.fatal "Error" true

log.finish "DONE"
