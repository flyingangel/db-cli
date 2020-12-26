# db-cli

A set of commands for easier mysql manipulation such as create, delete, import, export, backup database

## Install

Simply run `./install.sh` (as root) to install the `db` command.

A configurator helper will show up to ask you to configure mysql username, password, paths, etc. These steps are optional and can be rerun through this install script.

Finally type `db` in the terminal to test.

## How to use

A manual page is also installed with the script and it is accessible through `man db-cli`

Exemple of some commands :

    db list
    db export [database_name]
    db import [database_name]
    db delete [database_name]

### Configuring remote server for import and export operation

In `config/config.ini` file, configure a tab-seperated array

    #   Host    Description Port
    SERVERLIST=$(cat <<'EOF'
        X.X.X.X "My server" 1234
    EOF
    )

The default port is `22` and is optional

## Uninstall

`db` command is installed in `/usr/local/bin`.

The man page is installed in `/usr/local/man/man1`.

Use the script `uninstall.sh` to remove them automatically.

## Development

Test and update man page

    pandoc man/manpage.md -s -t man | /usr/bin/man -l -

Build man page

    pandoc man/manpage.md -s -t man | gzip > man/manpage.1.gz
