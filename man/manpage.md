% db-cli(1) 1.0 ZEAEAZE
% Thanh Trung NGUYEN
% January 2021

# NAME

db-cli - Database CLI

# SYNOPSIS

**db** [_OPTIONS_] [_COMMAND_]

# DESCRIPTION

Database tools for CLI

# OPTIONS

**-h, --help**
: display help message

# COMMAND

**ba [_SUBDIR_], backupall [_SUBDIR_]**
: backup all database; if subDir is specified, put all backups in this sub-directory

**c _DATABASE_, create _DATABASE_**
: create a database

**copy _DATABASE-SOURCE_ _DATABASE-DESTINATION_**
: copy a database to another database, create new if not exists

**d _DATABASE_, delete _DATABASE_, drop _DATABASE_**
: delete a database

**e _DATABASE_ [_OPT_], export _DATABASE_ [_OPT_]**
: export a database

> **--file**=/path/to/file

> > specifying an export file instead of exporting to the backup folder; --file="." will put the file in the current folder

> **--remote**[=IP]

> > export from a remote location instead of localhost; if no IP is specified, use a preconfigured list

**exec _SQL_ [_DATABASE_]**
: restore a database chosen from a list of backup files

**i _DATABASE_ [_OPT_], import _DATABASE_ [_OPT_]**
: import a database

> **--file**=/path/to/file

> > specifying an input file for import instead of looking from the backup folder

> **--remote**[=IP]

> > import from a remote location instead of localhost; if no IP is specified, use a preconfigured list

**l, list**
: list databases

**ls, listsize**
: list databases and their size

**r _DATABASE_, restore _DATABASE_**
: restore a database chosen from a list of backup files

# EXAMPLES

**db** -h | **db** --help

**db** l | **db** list

**db** i _DATABASE_ | **db** import _DATABASE_ --file=/path/to/file

**db** i _DATABASE_ --remote

**db** i _DATABASE_ --remote="1.1.1.1"

**db** exec "SHOW DATABASES"

**db** exec "SHOW TABLES" _DATABASE_

# SEE ALSO

Full documentation at https://github.com/flyingangel/db-cli.git

# COPYRIGHT

Copyright © 2021 Thanh Trung NGUYEN
