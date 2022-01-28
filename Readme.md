# MySQL Tools

##### Command-line shell scripts for managing MySQL databases.

### Introduction

Backing up, restoring and copying MySQL databases via command-line is not as simple as it should be.
Lots of configuration options and edge-cases make you wast time searching for anwers on *Stack Overflow* and require
more work than it should.
Specially if the server is not on the local network and must be accessed via an SSH tunnel.

This project provides a small set of Bash scripts that make these common operations trivially simple and easy.

> **Note:** branch `laravel` (or any `1.x` version) holds an old version suitable for integration with Laravel projects.
> 
> The current version can be used independently of any project or progamming language. You just need **Bash** installed on your system.
>
> It can be installed globally on your computer so that you can use the provided commands independently
> with any database, local or remote.

## Installation

### Installing standalone

Clone the repository somewhere on your computer.

You can then either:
1. copy the files into one of the folders on your PATH, or
2. add the project's directory to your environment's `PATH` variable.

The second option has the added benefit that you may update the tools to the latest version easily by issuing a `git pull` command.

### Installing via Composer

##### To install globally on your system:

```
composer global require impactwave/mysql-tools
```

If you haven't done it before, add `~/.composer/vendor/bin` to your path, so that you may execute the scripts from
anywhere on your computer.

##### Example:

Add this to your shell environment (ex: at `~/.profile` or `~/.bash_profile`):

	export PATH=$PATH:./vendor/bin

##### To install on your PHP project only

Add the following to our `composer.json` file:

```
"require": {
    "impactwave/mysql-tools": "^2.0"
},
```

Or, if you want the latest development version (not recommended):
```
"require": {
    "impactwave/mysql-tools": "dev-master@dev"
},
```

> **Note:** do not checkout `1.x` versions unless you want the Laravel-specific versions of these tools. 

If you haven't done it before, add `vendor/bin` to your path, so that you may execute the scripts from your project's root folder.

## Usage

### mysql-backup

```
Backs up a MySQL database with sensible default options. Supports SSH connections to remote servers.

Usage: mysql-backup [options] <database> [<archive_name>]

Parameters:
  database        Name of database to be backed up.
  archive_name    Filename with optional path and without extension (.tgz or .sql will be appended).
                  If not specified or if it ends with / (it's a directory name), the backup archive will be named
                  'HOST-YYYY-MM-DD-hhmmss.tgz', where HOST is the target server's host name, YYYY-MM-DD is the current
                  date and hhmmss is the current time.

Options:
  -t "<tables>"   Space-delimited list of tables to be backed up (ex: -t \"table1 table2\").
  -h <hostname>   Hostname for direct network connection. Defaults to 'localhost'.
  -u <username>   Username for database connection. Defaults to the current user.
  -p <password>   Password for database connection.
  -H <hostname>   Hostname for ssh connection.
  -P <port>       Port for SSH connnection. Defaults to 22.
  -U <username>   Username for SSH connnection. Note: you must use key-based ssh authentication; there is no option to
                  specify a password.
  -C              Do not compress the backup; the backup file will be an SQL script instead of a compressed archive.
  -D              Do not set DEFINER clauses to the current user (which is done to prevent errors for missing users when
                  the backup is restored).

Notes:
 - if an compressed archive is generated, it will contain a file named '$dumpfile'.
 - if using an SSH connection and -n is specified, the backup file will be copied to the local machine using network
   compression.
```

## License

MIT

The MIT License (MIT)

Copyright (c) 2014 Impactwave Lda

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
