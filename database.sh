#!/bin/bash
# ======
# DB-CLI
# ======

#set working dir
DIR_ROOT=$(dirname -- "$(realpath "$0")")
cd "$DIR_ROOT" || exit 1
source config/autoload.sh

# ===========
# = Actions =
# ===========

# Dispatcher
function dispatcher() {
    local action=$1

    #remove one argument
    shift

    case $action in
    "-h" | "--help") man ;;
    "l" | "list") database_list ;;
    "ls" | "listsize") database_list_size ;;
    "c" | "create") database_create "$@" ;;
    "d" | "delete" | "drop") database_drop "$@" ;;
    "i" | "import") database_import "$@" ;;
    "e" | "export") database_export "$@" ;;
    "ba" | "backupall") database_backup_all "$@" ;;
    "r" | "restore") database_restore "$@" ;;
    "copy") database_copy "$@" ;;
    "exec") database_exec "$@" ;;
    *)
        log.fatal "$1" "ERROR Unknown command"
        man
        ;;
    esac
}

# helper
function man() {
    log.header "-- DB-CLI --"
    log.header "Hash: $(git branch) #$(git rev-parse --short HEAD)"
    log.header "To show the manual: man db-cli"
}

function database_list() {
    mysql.request_auth
    log.header "List of databases"
    mysql.list "$CFG_DB_USER" "$CFG_DB_PASSWORD"
}

function database_list_size() {
    mysql.request_auth
    log.header "List of databases (non-empty) and their size"
    mysql.list_size "$CFG_DB_USER" "$CFG_DB_PASSWORD"
}

function database_create() {
    log.header "Create database $1"
    helper.request_db_param "$1"
    mysql.request_auth
    mysql.create "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$1"
    log.success "Database $1 created"
}

function database_drop() {
    log.header "Deleting database $1"
    helper.request_db_param "$1"

    if input.askcontinue "Are you sur you want to delete the database \"$1\" ?"; then
        mysql.request_auth
        mysql.drop "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$1"
        log.success "Database $1 deleted"
    else
        log.info "Aborted"
    fi
}

function database_export() {
    local file size
    local remote="localhost"
    local port=22

    log.header "Export database $1"

    #opts
    POSITIONAL=()
    for i in "$@"; do
        case $i in
        --file=*) file="${i#*=}" ;;
        --remote*) remote="${i#*=}" ;;
        -*) shift ;; #unknown params with dash
        *) POSITIONAL+=("$i") ;;
        esac
    done
    #restore positional parameters
    set -- "${POSITIONAL[@]}"

    helper.request_db_param "$1"

    date.datetime date true
    date=${date//:/-}

    #export at current location
    if [[ $file == "." ]]; then
        file=$(pwd -P)/$date.$1.sql.gz
    fi

    #if output file is not specified
    if [ -z "$file" ]; then
        backup.get_backup_dir dir "$1"
        file=$date.$1.sql.gz

        #if db dir exist put file in db dir
        if [ -n "$dir" ]; then
            file=$dir/$file
        fi
    fi

    #export from localhost
    if [ "$remote" == "localhost" ]; then
        mysql.request_auth

        if ! (mysql.exist "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$1"); then
            log.error "Database $1 not exist"
            exit 1
        fi

        log.info "Exporting DB $1"
        mysql.export "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$1" "$file"

        if [ -f "$file" ]; then
            #check file size
            file.size.readable size "$file"

            log.success "DONE $file ($size)"
        else
            log.error "Problem with export"
            exit 1
        fi
    else
        #export from remote server
        #remote value is not localhost ask for server
        if [ "$remote" == "--remote" ]; then
            log.newline
            mysql.remote.ask_server remote port
        fi

        if [ -z "$remote" ]; then
            log.error "Remote server is not set"
            exit 1
        fi

        log.newline
        log.info "Exporting remote DB $1 from $remote"

        mysql.remote.export "$file" "$remote" "$port" "$REMOTE_SSH_USER" "$1" "$REMOTE_DB_USER" "$REMOTE_DB_PASSWORD"

        #check file size
        file.size.readable size "$file"

        #check error
        if [ "$size" == "0 Kb" ]; then
            log.error "Problem with export or connecting to remote server"
            exit 1
        else
            log.success "DONE $file ($size)"
        fi
    fi
}

function database_import() {
    local file realfile
    local remote="localhost"
    local port=22

    log.header "Import database $1"

    #opts
    POSITIONAL=()
    for i in "$@"; do
        case $i in
        --file=*) file="${i#*=}" ;;
        --remote*) remote="${i#*=}" ;;
        -*) shift ;; #unknown params with dash
        *) POSITIONAL+=("$i") ;;
        esac
    done
    #restore positional parameters
    set -- "${POSITIONAL[@]}"

    helper.request_db_param "$1"

    #import from localhost
    if [ "$remote" == "localhost" ]; then
        mysql.request_auth

        #if input file is not specified
        if [ -z "$file" ]; then
            backup.get_backup_dir dir "$1"

            #if db dir exist get file from db dir
            if [ -n "$dir" ]; then
                file=$dir/$(ls "$dir" | tail -n 1)
                file=$(realpath "$file")
            fi
        fi

        #check file exist
        helper.get_dump realfile "$file"

        if [ ! -f "$realfile" ]; then
            if [ ! -f "$realfile" ]; then
                log.error "File $realfile does not exist"
                exit 1
            fi
        fi

        #begin import
        log.info "Importing DB $1 from $file"
        timer.start
        mysql_database_import "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$1" "$realfile"
        log.success "DONE ($(timer.end)s)"

    else
        #remote value is not localhost ask for server
        if [ "$remote" == "--remote" ]; then
            log.newline
            mysql.remote.ask_server remote port
            log.newline
        fi

        if [ -z "$remote" ]; then
            log.error "Remote server is not set"
            exit 1
        fi

        timer.start
        
        if mysql.remote.import "$remote" "$port" "$REMOTE_SSH_USER" "$1" "$REMOTE_DB_USER" "$REMOTE_DB_PASSWORD" "$CFG_DB_USER" "$CFG_DB_PASSWORD"; then
            log.success "DONE ($(timer.end)s)"
        else
            log.error "Error"
            exit 1
        fi
    fi
}

function database_restore() {
    local file
    log.header "Restore database $1"
    helper.request_db_param "$1"
    backup.list file "$1" || exit 1

    #incorrect number
    if [ -z "$file" ]; then
        log.error "Incorrect number"
        exit 1
    fi

    database_import "$@" --file="$file"
}

function database_copy() {
    log.header "Copy database"
    mysql.request_auth
    helper.request_db_param "$1"
    helper.request_db_param "$2" 3

    #check if db source exist
    if ! (mysql.exist "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$1"); then
        log.error "Database $1 not exist"
        exit 1
    fi

    #check if destination exist
    if mysql.exist "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$2"; then
        if ! (input.askcontinue "Do you want to overwrite database \"$2\" ?"); then
            log.info "Aborted"
            exit
        fi
    fi

    #delete then create destination DB
    mysql.drop "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$2"
    mysql.create "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$2"

    log.info "Copying $1 to $2"

    #copy using flux
    if [ -z "$CFG_DB_PASSWORD" ]; then
        mysqldump --single-transaction -u "$CFG_DB_USER" "$1" | mysql -u "$CFG_DB_USER" "$2"
    else
        mysqldump --single-transaction -u "$CFG_DB_USER" -p"$CFG_DB_PASSWORD" "$1" | mysql -u "$CFG_DB_USER" -p"$CFG_DB_PASSWORD" "$2"
    fi

    log.success "DONE"
}

function database_exec() {
    log.header "Execute SQL"
    mysql.request_auth

    #check sql
    if [ -z "$1" ]; then
        log.error "Missing parameter 2"
        exit 1
    fi

    shopt -s nocasematch
    #show process list
    if [[ "$1" =~ "processlist" ]] || [[ "$1" =~ "show tables" ]]; then
        mysql.exec_full "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$1" "$2"
    else
        mysql.exec "$CFG_DB_USER" "$CFG_DB_PASSWORD" "$1" "$2"
    fi
}

function database_backup_all() {
    local ignore dir dbs today file user pass
    local subdir=$1

    log.header "Backup all databases"

    today=$(date '+%Y%m%d')

    if [[ -v CFG_DB_USER ]]; then
        user=$CFG_DB_USER
    else
        user=$CFG_DB_BACKUP_USER
    fi

    if [[ -v CFG_DB_PASSWORD ]]; then
        pass=$CFG_DB_PASSWORD
    else
        pass=$CFG_DB_BACKUP_PASSWORD
    fi

    #list all database
    if [[ -n $pass ]]; then
        dbs="$(mysql -u "$user" -p"$pass" -Bse 'show databases')"
    else
        dbs="$(mysql -u "$user" -Bse 'show databases')"
    fi

    dir=$CFG_DB_BACKUP_DIR

    #point to subdir if define
    [[ -n $subdir ]] && dir=$dir/$subdir
    mkdir -p "$dir"

    for db in $dbs; do
        #trim white space
        db="${db%"${db##*[![:space:]]}"}"
        ignore=false

        #if array count is not empty
        if [ ${#CFG_DB_BACKUP_IGNORE[@]} -ne 0 ]; then
            for i in "${CFG_DB_BACKUP_IGNORE[@]}"; do
                [[ $db == "$i" ]] && ignore=true && break
            done
        fi

        exit

        #dump DB if not ignored
        if ! $ignore; then
            log.info "Backing up DB $db"

            file="${dir}/${CFG_DB_BACKUP_PREFIX}${today}.${db}.sql.gz"

            if [[ -n $pass ]]; then
                mysqldump --single-transaction --lock-tables=false -u "$user" -p"$pass" "$db" | gzip >"$file"
            else
                mysqldump --single-transaction --lock-tables=false -u "$user" "$db" | gzip >"$file"
            fi

            file.size.readable size "$file"
            log.info ">> $file ($size)"
        fi
    done
}

# ========
# = INIT =
# ========
#case number of args in command line
case $# in
0) man ;;
*) dispatcher "$@" ;;
esac
