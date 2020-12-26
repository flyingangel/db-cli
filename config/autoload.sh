#!/bin/bash
#autoload functions
for file in ./functions/*; do
	source "$file"
done

if [[ ! -f $DIR_ROOT/config/config.ini ]]; then
	echo "Missing config file"
	exit 1
fi

#load config file
source "$DIR_ROOT/config/config.ini"

#load external lib
source "$DIR_ROOT/shell_modules/shell-lib/autoload.sh"
