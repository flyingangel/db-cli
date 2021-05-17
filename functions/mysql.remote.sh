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

    ssh -p "$port" "$ssh_user@$ip" "mysqldump $args --single-transaction -u $db_user -p$db_pass $db_name | gzip --best" >"$file"

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

    log.info "Importing $db_name from $1"

    #delete then create destination
    mysql.drop "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$db_name"
    mysql.create "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$db_name"

    set -o pipefail

    #import from remote server
    if [ -z "$CFG_DB_PASSWORD" ]; then
        ssh -p "$port" "$ssh_user@$ip" "mysqldump $args --single-transaction -u $db_user -p$db_pass $db_name | gzip --best" | gunzip | mysql -u "$CFG_DB_USER" "$db_name"
    else
        ssh -p "$port" "$ssh_user@$ip" "mysqldump $args --single-transaction -u $db_user -p$db_pass $db_name | gzip --best" | gunzip | mysql -u "$CFG_DB_USER" -p"$CFG_DB_PASSWORD" "$db_name"
    fi

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

#return a chosen server IP
#mysql.remote.ask_server result_ip
function mysql.remote.ask_server() {
    local input ip list i host hostList

    list=$(printf '%s' "$(cat /etc/hosts)" | awk -F "\\\s+" '{print $1"\t"$2}')
    i=1
    hostList=()

    log.header "$(printf '   %-15s\t%-30s\t%s\n' 'IP' 'Host' '#')"

    while read -r line; do
        #test for valid IP
        if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
            ip=$(printf '%s' "$line" | awk -F "\t" '{print $1}')
            host=$(printf '%s' "$line" | awk -F "\t" '{print $2}')

            if [[ $ip == "127.0.0.1" ]]; then
                continue
            fi

            printf '   %-15s\t%-30s\t%s\n' "$ip" "$host" "$i"

            hostList+=("$ip")
            ((i++))
        fi
    done < <(echo "$list")

    log.newline

    read -rp "Choose a server number: " input

    #test if is a number
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        log.error "Invalid number"
        exit 1
    fi

    [[ $input -gt 1 ]] && ((input--))
    host="${hostList[$input]}"

    eval "$1=$host"
}
