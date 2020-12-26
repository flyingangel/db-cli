#!/bin/bash

#export sql from remote server
#mysql.remote.export target_file ip port ssh_user db_name db_user db_pw
function mysql.remote.export() {
    local port=$3
    local ssh_user=$4
    local db_name=$5
    local db_user=$6
    local db_pass=$7

    if [ -z "$1" ]; then
        exit 1
    fi

    mysql.remote.request_auth "$port" "$ssh_user" "$db_name" "$db_user" "$db_pass"
    #final check for fatal error
    if ! mysql.remote.check_auth "$port" "$ssh_user" "$db_name" "$db_user" "$db_pass"; then
        log.warning "Invalid authentification"
        return 1
    fi

    ssh -p "$port" "$ssh_user@$2" "mysqldump --single-transaction -u $db_user -p$db_pass $db_name | gzip --best" >"$1"
}

#import sql from remote server
#mysql.remote.import ip port ssh_user db_name remote_db_user remote_db_pw local_db_user local_db_pw
function mysql.remote.import() {
    local port=$2
    local ssh_user=$3
    local db_name=$4
    local db_user=$5
    local db_pass=$6

    mysql.remote.request_auth "$port" "$ssh_user" "$db_name" "$db_user" "$db_pass"
    #final check for fatal error
    if ! mysql.remote.check_auth "$port" "$ssh_user" "$db_name" "$db_user" "$db_pass"; then
        log.warning "Invalid authentification"
        return 1
    fi

    log.info "Importing $db_name from $1"

    #delete then create destination
    mysql.drop "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$4"
    mysql.create "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$4"

    set -o pipefail

    #import from remote server
    if [ -z "$8" ]; then
        ssh -p "$port" "$ssh_user@$1" "mysqldump --single-transaction -u $db_user -p$db_pass $db_name | gzip --best" | gunzip | mysql -u "$7" "$db_name"
    else
        ssh -p "$port" "$ssh_user@$1" "mysqldump --single-transaction -u $db_user -p$db_pass $db_name | gzip --best" | gunzip | mysql -u "$7" -p"$8" "$db_name"
    fi
}

#request auth when importing from remote
#mysql.remote.request_auth
function mysql.remote.request_auth() {
    if [ -z "$port" ]; then
        port=22
    fi

    #empty ssh user
    if [ -z "$ssh_user" ]; then
        read -rp "Enter SSH username of remote server: " ssh_user
    fi

    #empty database name
    if [ -z "$db_name" ]; then
        read -rp "Enter the database name to export: " db_name
    fi

    #empty mysql user
    if [ -z "$db_user" ]; then
        read -rp "Enter remote mysql username: " db_user
    fi

    #empty mysql pw
    if [ -z "$db_pass" ]; then
        input.read_secret db_pass "Enter remote mysql password: "
    fi
}

#check if auth is correct
#mysql.remote.check_auth
function mysql.remote.check_auth() {
    mysql.remote.request_auth "$port" "$ssh_user" "$db_name" "$db_user" "$db_pass"

    #final check
    if [[ -z "$port" || -z "$ssh_user" || -z "$db_name" || -z "$db_user" || -z "$db_pass" ]]; then
        return 1
    fi
}

#list remote server defined in config.ini
#mysql.remote.list_server
function mysql.remote.list_server() {
    local list i

    echo -e "#\tHost\tDescription"
    list=$(printf '%s' "$SERVERLIST" | awk -F "\t" '{print $1"\t"$2}')
    i=1
    echo "$list" | while read -r line; do
        echo -e "$i\t$line"
        ((i++))
    done
}

#return a chosen server IP
#mysql.remote.ask_server result_ip result_port
function mysql.remote.ask_server() {
    local input ip p

    mysql.remote.list_server
    echo

    read -p "Choose a server number: " input

    #conver number to IP
    ip=$(printf '%s' "$SERVERLIST" | awk -F "\t" -v i="$input" 'FNR == i {print $1}')
    p=$(printf '%s' "$SERVERLIST" | awk -F "\t" -v i="$input" 'FNR == i {print $3}')

    #invalid
    if [ -z "$ip" ]; then
        exit 1
    fi

    eval "$1=$ip"
    eval "$2=$p"
}
