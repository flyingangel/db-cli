#!/bin/bash

#Execute sql request
#mysql.exec db_user db_pwd sql db_name
function mysql.exec() {
    if [ -z "$2" ]; then
        mysql -u "$1" -e "$3;" "$4"
    else
        mysql -u "$1" -p"$2" -e "$3;" "$4"
    fi
}

#Execute sql with full output as in console
#mysql.exec_full db_user db_pwd sql db_name
function mysql.exec_full() {
    if [ -z "$2" ]; then
        mysql -vvv -u "$1" -e "$3;" "$4"
    else
        mysql -vvv -u "$1" -p"$2" -e "$3;" "$4"
    fi
}

#Execute sql in silent mode and no header and no debug
#mysql.exec_silent db_user db_pwd sql db_name
function mysql.exec_silent() {
    if [ -z "$2" ]; then
        mysql -sN -u "$1" -e "$3;"
    else
        mysql -sN -u "$1" -p"$2" -e "$3;"
    fi
}

#Export database
#mysql.export db_user db_pwd db_name
function mysql.export() {
    local file="$3.sql.gz"
    local password

    #custom filename
    if [ -n "$4" ]; then
        file="$4"
    fi

    password=$([[ -n $2 ]] && echo "-p$2")

    #detect if pv command exist
    if [[ -t 1 && -n $(which pv) ]]; then
        mysqldump --single-transaction --routines --events -u "$1" "$password" "$3" | pv -W -D 1 | gzip --best  >"$file"
    else
        mysqldump --single-transaction --routines --events -u "$1" "$password" "$3" | gzip --best >"$file"
    fi

    #shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1
}

#Import database
#mysql_import db_user db_pwd db_name
function mysql.import() {
    local file="$3.sql"
    local password

    #custom filename
    if [ -n "$4" ]; then
        file=$4
    fi

    mysql.drop "$1" "$2" "$3"
    mysql.create "$1" "$2" "$3"

    password=$([[ -n $2 ]] && echo "-p$2")

    #detect if pv command exist
    if [[ -t 1 && -n $(which pv) ]]; then
        pv -D 1 "$file" | mysql -u "$1" "$password" "$3"
    else
        mysql -u "$1" "$password" "$3" <"$file"
    fi

    #shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1
}

#List all database
#mysql.list db_user db_pwd
function mysql.list() {
    mysql.exec_full "$1" "$2" 'SHOW DATABASES'
}

#List all database and their size
#mysql.list_size db_user db_pwd
function mysql.list_size() {
    mysql.exec_full "$1" "$2" "SELECT table_schema 'Databases', ROUND(SUM(data_length + index_length) / 1048576) 'Size in Mb' FROM information_schema. TABLES GROUP BY table_schema ORDER BY \`Size in Mb\`"
}

#Create database
#mysql.create db_user db_pwd db_name
function mysql.create() {
    mysql.exec "$1" "$2" "CREATE DATABASE IF NOT EXISTS \`$3\`"
}

#Drop database
#mysql.drop db_user db_pwd db_name
function mysql.drop() {
    mysql.exec "$1" "$2" "DROP DATABASE IF EXISTS \`$3\`"
}

#Check if database exist
#if (mysql.exist db_user db_pwd db_name); then
function mysql.exist() {
    local result

    result=$(mysql.exec_silent "$1" "$2" "SHOW DATABASES LIKE '$3'")

    if [ -z "$result" ]; then
        return 1
    else
        #return code 0 mean everything is OK
        return 0
    fi
}

#Request username and password if variable is not set (empty string is still considered set)
#mysql.request_auth
function mysql.request_auth() {
    #if username not set

    if [[ -z $CFG_DB_USER ]]; then
        mysql.request_user CFG_DB_USER
    fi

    #if password is not set
    if [[ ! -v CFG_DB_PASSWORD ]]; then
        mysql.request_password CFG_DB_PASSWORD
    fi
}

#Request mysql username with an option to raise warning if username is empty
#mysql.request_user result raiseWarning
function mysql.request_user() {
    local input
    read -rp "Enter your mysql username: " input

    #abort if empty username
    if [ -z "$input" ]; then
        log.warning "Empty username"
    fi

    eval "$1=\$input"
}

#Request mysql password
#mysql.request_password result
function mysql.request_password() {
    local pass

    input.read_secret pass "Enter your mysql password: "

    if [ -z "$pass" ]; then
        log.warning "Used empty password"
    fi

    eval "$1=\$pass"
}
