#!/bin/bash

#export sql from remote server
#mysql.remote.export target_file ip port ssh_user db_name db_user db_pw remote_mysql_args
function mysql.remote.export() {
    local file=$1
    local ip=$2
    local port=$3
    local ssh_user=$4
    local db_name=$5
    local db_user=$6
    local db_pass=$7
    local args=$8

    set -o pipefail

    ssh -p "$port" "$ssh_user@$ip" "mysqldump $args --single-transaction --routines --events -u $db_user -p$db_pass $db_name | (command -v pigz >/dev/null && pigz --best || gzip --best)" >"$file"

    #shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1
}

#import sql from remote server
#mysql.remote.import ip port ssh_user db_name remote_db_user remote_db_pw remote_arg remote_mysql_args
function mysql.remote.import() {
    local ip=$1
    local port=$2
    local ssh_user=$3
    local db_name=$4
    local db_user=$5
    local db_pass=$6
    local args=$7

    set -o pipefail

    log.info "Importing $db_name from $1"

    #delete then create destination
    mysql.request_auth
    mysql.drop "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$db_name"
    mysql.create "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$db_name"

    #import from remote server
    ssh -p "$port" "$ssh_user@$ip" "mysqldump $args --single-transaction --routines --events -u $db_user -p$db_pass $db_name | (command -v pigz >/dev/null && pigz --best || gzip --best)" | file.gunzip | mysql -u "$CFG_DB_USER" -p"$CFG_DB_PASSWORD" "$db_name"

    #shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1
}

#request auth when importing from remote
#mysql.remote.request_auth
function mysql.remote.request_auth() {
    #empty ssh user
    if [ -z "$REMOTE_SSH_USER" ]; then
        input.read REMOTE_SSH_USER "Enter SSH username of remote server: "
    fi

    #empty mysql user
    if [ -z "$REMOTE_DB_USER" ]; then
        input.read REMOTE_DB_USER "Enter remote mysql username: " REMOTE_DB_USER
    fi

    #empty mysql pw
    if [ -z "$REMOTE_DB_PASSWORD" ]; then
        input.read_secret REMOTE_DB_PASSWORD "Enter remote mysql password: "
    fi

    #final check for fatal error
    if [[ -z $REMOTE_SSH_USER || -z $REMOTE_DB_USER || -z $REMOTE_DB_PASSWORD ]]; then
        return 1
    fi
}
