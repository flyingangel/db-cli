#!/bin/bash
#uninstaller script

#set working dir
DIR_ROOT=$(dirname -- "$0")
cd "$DIR_ROOT" || exit 1

#load external lib
source shell_modules/shell-lib/autoload.sh

if ! right.is_root; then
    log.error "Sudo permission is required to install the binary"

    exit 1
fi

{
    uninstall_binary "db"
    uninstall_manpage "db-cli.1.gz"
} || log.fatal "Error" true

log.finish "DONE"
