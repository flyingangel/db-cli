#!/bin/bash

#Get custom backup dir
#backup.get_backup_dir result db_name
function backup.get_backup_dir() {
    local backup

    #if backup folder is defined
    if [ -n "$CFG_DB_DIR_BACKUP" ]; then
        #create folder if not exist
        if [ ! -d "$CFG_DB_DIR_BACKUP" ]; then
            mkdir -p "$CFG_DB_DIR_BACKUP"
        fi

        backup=$CFG_DB_DIR_BACKUP

        #if 2nd param is specified it is the db_name
        if [ -n "$2" ]; then
            if [ ! -d "$backup/$2" ]; then
                mkdir "$backup/$2"
            fi

            backup=$backup/$2
        fi

        #begin with .
        if [[ $backup == .* ]]; then
            backup=$(realpath "$backup")
        fi

        eval "$1=$backup"
        return 0
    fi

    #db dir not exist
    return 1
}

#Get custom tmp dir
#backup.get_tmp_dir result
function backup.get_tmp_dir() {
    local dir

    #guess where the backup folder is
    if [ -n "$CFG_DB_DIR_TMP" ]; then
        if [ ! -d "$CFG_DB_DIR_TMP" ]; then
            mkdir -p "$CFG_DB_DIR_TMP"
        fi

        dir=$CFG_DB_DIR_TMP
    else
        dir=/tmp
    fi

    eval "$1=$dir"
}

#List backup files
#backup.list result dbName
function backup.list() {
    local dir count input files file_list target
    backup.get_backup_dir dir "$2"

    #if backup folder exist
    if [ -d "$dir" ]; then
        count=$(ls -1q "$dir" | wc -l)
        log.info "Found $count backups"
        log.newline

        files=$(ls -r "$dir")
        echo "$files" | nl
        mapfile -t file_list <<< "$files"

        log.newline
        printf "To restore a version, select a number (default 1): "
        read -r input
        log.newline

        if ! [[ "$input" =~ ^[0-9]+$ ]]; then
            log.error "Number only!"
            exit 1
        fi

        [[ $input -gt 1 ]] && ((input--))
        target="${file_list[$input]}"

        eval "$1=$target"
    else
        log.header "No backup found"
        return 1
    fi
}
