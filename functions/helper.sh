#!/bin/bash

#Get sql file. If file exist return directly. If an unzip version exist return a tmp file
#helper.get_dump result filename
function helper.get_dump() {
    local tmp tmpDir
    local file=$2

    eval "$1=$file"

    #check file exist
    if [ ! -f "$file" ]; then
        #if file not exist consider the zipped file
        if [ -f "$file.gz" ]; then
            file=$file.gz
        else
            return 1
        fi
    fi

    #get tmp file path
    backup.get_tmp_dir tmpDir
    # bash generate random 32 character alphanumeric string (lowercase only)
    #shellcheck disable=2002
    tmpName=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    tmp=$tmpDir/$tmpName.sql

    #remove old tmp
    if [[ -f $tmpDir/$tmpName.sql ]]; then
        rm "$tmpDir/$tmpName.sql"
    fi

    #end with .gz extract it
    if [[ $file =~ \.gz$ ]]; then
        gunzip -c -f "$file" >"$tmp"
        file=$tmp
    fi

    #end with .zip extract it
    if [[ $file =~ \.zip$ ]]; then
        #scan for file name
        for f in *.zip; do
            file=$f
        done

        unzip "$file" -d "$tmpDir"
        mv "$tmpDir/$file" "$tmpDir/tmp.sql"
    fi

    #check exist
    if [ ! -f "$file" ]; then
        return 1
    fi

    eval "$1=$file"
}

#Generic check if additional params is passed to the command
#helper.request_db_param $1 argument_number
function helper.request_db_param() {
    local param_number=2

    if [[ -v 2 && -n "$2" ]]; then
        param_number=$2
    fi

    if [ -z "$1" ]; then
        log.error "Missing parameter $param_number" db_name
        exit 1
    fi
}
