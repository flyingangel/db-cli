#!/bin/bash
#helper to install config files

#set working dir
DIR_CURRENT=$(dirname -- "$0")
cd "$DIR_CURRENT" || exit 1

#load external lib
source ../shell_modules/shell-lib/autoload.sh

#Generate a config file from a template
#configurator.parse template_file destination_file
function main() {
    local list template var value overwrite

    echo "-- All settings are optional --"

    configurator.section "Database"
    configurator.ask DB_USER "Set a mysql user"

    if [[ -n $DB_USER ]]; then
        configurator.ask DB_PASSWORD "Set mysql password for user \"$DB_USER\""
    fi

    configurator.section "Location"
    configurator.ask DB_DIR_MAIN "Set a location to store DB" "./runtime/db"
    configurator.ask DB_DIR_BACKUP "Set a location to store backups" "./runtime/backup"
    configurator.ask DB_DIR_TMP "Set a location to store tmp files" "./runtime/tmp"

    configurator.section "Remote Database"
    if configurator.askcontinue "Configure remote authentification?"; then
        configurator.ask REMOTE_SSH_USER "Set a remote SSH user"
        configurator.ask REMOTE_DB_USER "Set a remote mysql user"

        if [[ -n $REMOTE_DB_USER ]]; then
            configurator.ask REMOTE_DB_PASSWORD "Set mysql password for remote user \"$REMOTE_DB_USER\""
        fi
    fi

    configurator.section "Backup"
    if configurator.askcontinue "Configure backups settings?"; then
        configurator.ask DB_BACKUP_USER "Set a mysql user for backup operation" "$DB_USER"

        if [[ -n $DB_BACKUP_USER ]]; then
            configurator.ask DB_BACKUP_PASSWORD "Set mysql password for user \"$DB_BACKUP_USER\"" "$DB_PASSWORD"
        fi

        configurator.ask DB_BACKUP_DIR "Set a location to store backups" "$DB_DIR_BACKUP/all"
        configurator.ask DB_BACKUP_PREFIX "Set prefix for backups"
    fi

    configurator.section "Summary"

    template=$(cat "$1")

    #load all variable in template
    #shellcheck disable=SC2016
    list=$(grep -oP '\$TPL\.\w+' "$1" | sort -r)

    #set dim text
    printf "\e[2m"

    for const in $list; do
        var=${const/\$TPL\./}
        eval "value=\${$var}"
        template=${template/$const/$value}
        echo "$var=$value"
    done

    #reset text color
    printf "\e[22m"

    #test existence
    [[ -f $2 ]] && overwrite="and overwrite "

    if configurator.askcontinue "Write these settings to $overwrite\"$(realpath "$2")\" ?"; then
        echo "$template" >"$2"
    fi

    echo
}

main "template.config.ini" "config.ini"
