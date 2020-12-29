% db-cli(1) 1.0 ZEAEAZE
% Thanh Trung NGUYEN
% January 2021

# NAME

db-cli - Database CLI

# SYNOPSIS

**db** [*OPTIONS*] [*COMMAND*]

# DESCRIPTION

Database tools for CLI

# OPTIONS

**-h, --help**
: display help message

# COMMAND

**ba [*SUBDIR*], backupall [*SUBDIR*]**
: backup all database; if subDir is specified, put all backups in this sub-directory

**c [*DATABASE*], create [*DATABASE*]**
: create a database

**copy [*DATABASE-SOURCE*] [*DATABASE-DESTINATION*]**
: copy a database to another database, create new if not exists

**d [*DATABASE*], delete [*DATABASE*], drop [*DATABASE*]**
: delete a database

**e [*DATABASE*] [*OPT*], export [*DATABASE*] [*OPT*]**
: export a database

> **--file**=/path/to/file

> > specifying an export file instead of exporting to the backup folder; **--file="."** will put the file in the current folder

> **--remote**[=IP]

> > export from a remote location instead of localhost; if no IP is specified, the host list is read from **/etc/hosts**

> **--remote-arg**=ARGS

> > additional mysql args to pass to remote server

**exec *SQL* [*DATABASE*]**
: restore a database chosen from a list of backup files

**i [*DATABASE*] [*OPT*], import [*DATABASE*] [*OPT*]**
: import a database

> **--file**=/path/to/file

> > specifying an input file for import instead of looking from the backup folder

> **--remote**[=IP]

> > import from a remote location instead of localhost; if no IP is specified, the host list is read from **/etc/hosts**

> **--remote-arg**=ARGS

> > additional mysql args to pass to remote server

**l, list**
: list databases

**ls, listsize**
: list databases and their size

**r [*DATABASE*], restore [*DATABASE*]**
: restore a database chosen from a list of backup files

# EXAMPLES

**db** -h | **db** --help

**db** l | **db** list

**db** i [*DATABASE*]

**db** import [*DATABASE*] --file=/path/to/file

**db** i [*DATABASE*] --remote

**db** i [*DATABASE*] --remote="1.1.1.1" --remote-arg="-h 2.2.2.2"

**db** export [*DATABASE*] --file="."

**db** exec "SHOW DATABASES"

**db** exec "SHOW TABLES" [*DATABASE*]

# SEE ALSO

Full documentation at https://github.com/flyingangel/db-cli.git

# COPYRIGHT

Copyright © 2021 Thanh Trung NGUYEN
