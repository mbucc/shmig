SHMIG [![Build Status](https://travis-ci.org/mbucc/shmig.svg?branch=master)](https://travis-ci.org/mbucc/shmig)
=====

A database migration tool written in BASH consisting of just one
file - [`shmig`](https://github.com/naquad/shmig/blob/master/shmig).

Automated Tests
-----

| Shell | DB  | Result |
| ----- | --- | ------ |
| /bin/bash | sqlite3 | ![](https://raw.githubusercontent.com/mbucc/shmig_test/master/badges/alpine-3.8-bash-sqlite3.png) |
| /bin/bash | mysql:5.7 | ![](https://raw.githubusercontent.com/mbucc/shmig_test/master/badges/alpine-3.8-bash-mysql-5.7.png) |
| /bin/bash | postgres:9.6 | ![](https://raw.githubusercontent.com/mbucc/shmig_test/master/badges/alpine-3.8-bash-postgres-9.6.png) |

See https://github.com/mbucc/shmig_test.



Quick Start
----------
```
  $ cd shmig
  $ make install
  $ cd $HOME
  $ mkdir migrations
  $ shmig -t sqlite3 -d test.db create mytable
  generated ./migrations/1470490964-mytable.sql
  $ cat ./migrations/1470490964-mytable.sql
  -- Migration: mytable
  -- Created at: 2016-08-06 09:42:44
  -- ====  UP  ====

  BEGIN;
  	PRAGMA foreign_keys = ON;

  COMMIT;

  -- ==== DOWN ====

  BEGIN;

  COMMIT;
  $ # In normal usage, you would add SQL to this migration file.
  $ shmig -t sqlite3 -d test.db migrate
  shmig: creating migrations table: shmig_version
  shmig: applying  'mytable'    (1470490964)... done
  $ ls -l test.db
  -rw-r--r--  1 mark  staff  12288 Aug  6 09:41 test.db
  $ shmig -t sqlite3 -d test.db rollback
  shmig: reverting 'mytable'    (1470490964)... done
  $ shmig -h | wc -l
  73
  $
```

Edit the function `sqlite3_up_text()` and `sqlite3_down_text()` in
shmig if you don't like the default SQL template.


Why?
----

Currently there are lots of database migration tools such as
[DBV](http://dbv.vizuina.com/), [Liquibase](http://www.liquibase.org/),
[sqitch](http://sqitch.org/), [Flyway](http://flywaydb.org/)
and other framework-specific ones (for Ruby on Rails, Yii, Laravel,
...). But they all are pretty heavy, with lots of dependencies (or
even unusable outside of their stack), some own DSLs...

I needed some simple, reliable solution with minimum dependencies
and able to run in pretty much any POSIX-compatible environment
against different databases (PostgreSQL, MySQL, SQLite3).

And here's the result.

Idea
----

RDMS'es are bundled along with their console clients. MySQL has
`mysql`, PostgreSQL has `psql` and SQLite3 has `sqlite3`. And that's
it! This is enough for interacting with database in batch mode w/o
any drivers or connectors.

Using client options one can make its output suitable for batch
processing with standard UNIX text-processing tools (`sed`, `grep`,
`awk`, ...). This is enough for implementing simple migration system
that will store current schema version information withing database
(see
[`SCHEMA_TABLE`](https://github.com/naquad/shmig/blob/a814690d5040e6aa8f05f112a8b66db9eedb1d07/shmig.conf.example#L21-L22)
variable in
[`shmig.conf.example`](https://github.com/naquad/shmig/blob/master/shmig.conf.example)).

Usage
-----

SHMIG tries to read configuration from the configuration file
`shmig.conf` in the current working directory.  A sample configuration
file is
[`shmig.conf.example`](https://github.com/naquad/shmig/blob/master/shmig.conf.example).

You can also provide an optional config override file by creating
the file `shmig.local.conf`.  This allows you to provide a default
configuration which is version-controlled with your project, then
specify a non-version-controlled local config file that you can use
to provide instance-specific config. (An alternative is to use
envrionment variables, though some people prefer concrete files to
nebulous environment variables.) This works even with custom config
files specified with the `-c` option.

You can also configure SHMIG from command line, or by using
environmental variables.  The command line settings have higher
priority than configuration files or environment settings.

Required options are:

  1. `TYPE` or `-t` - database type
  2. `DATABASE` or `-d` - database to operate on
  3. `MIGRATIONS` or `-m` - directory with migrations

All other options (see `shmig.conf.example` and `shmig -h`) are not necessary.

To simplify usage, create `shmig.conf` in your project root directory
with your configuration directives.  When you `shmig <action> ...` 
in that directory, shmig will use the configuration in that file.

For detailed information see `shmig.conf.example` and `shmig -h`.

Migrations
----------

Migrations are SQL files whose name starts with "`<UNIX TIMESTAMP>-`"
and end with ".sql".  The order that new migrations are applied is
[determined](https://github.com/naquad/shmig/blob/master/shmig#L481)
by the seconds-since-epoch time stamp in the filename, with the
oldest migration going first.

Each migration contains two special markers: `-- ====  UP ====`
that marks start of section that will be executed when migration
is applied and `-- ==== DOWN ====` that marks start of section that
will be executed when migration is reverted.

For example:

```
-- Migration: create users table
-- Created at: 2013-10-02 07:03:11
-- ====  UP  ====
CREATE TABLE `users`(
  id int not null primary key auto_increment,
  name varchar(32) not null,
  email varchar(255) not null
);

CREATE UNIQUE INDEX `users_email_uq` ON `users`(`email`);
-- ==== DOWN ====
DROP TABLE `users`;
```

Everything between `-- ==== UP ====` till `-- ==== DOWN ====` will 
be executed when migration is applied and everything between 
`-- ==== DOWN ====` till the end of file will be executed when
migration is reverted. If migration is missing marker or contents
of marker is empty then appropriate action will fail (i.e. if you're
trying to revert migration that has no or empty `-- ==== DOWN ====`
marker you'll get an error and script won't execute any migrations
following script with error). Also note those semicolons terminating
statements. They're required because you're basically typing that
into your database CLI client.

SHMIG can generate skeleton migration for you, see `create` action.

Migrations with test data
----------
One nice feature of Liquibase is contexts, which are used to
implement different behavior based on environment; for example,
in a development environment you can insert test data.

`shmig` can support this with symbolic links.  For example, say
your production migrations are in `prod` and test data in `test`:

```
.
└── migrations
    ├── prod
    │   └── 1485643154-create_table.sql
    └── test
        └── 1485648520-testdata.sql
```

To create a test environment context, link the prod SQL in test directory:

```
$ cd migrations/test/
$ ln -s ../prod/1485643154-create_table.sql
```


```
.
└── migrations
    ├── prod
    │   └── 1485643154-create_table.sql
    └── test
        ├── 1485643154-create_table.sql -> ../prod/1485643154-create_table.sql
        └── 1485648520-testdata.sql
```

When applying migrations to test, point shmig to the test directory either
via the command line or using the local config override file.

Since migrations are applied in order of epoch seconds in the file name,
this works.


Current state
-------------

Stable and maintained.  Pull requests welcome.


Security considerations
-----------------------

Password is passed to `mysql` and `psql` via environment variable.
This can be a security issue if your system allows other users to
read environment of process that belongs to another user. In most
Linux distributions with modern kernels this is forbidden. You can
check this (on systems supporting /proc file system) like this:
`cat /proc/1/env` - if you get permission denied error then you're
secure.

Efficiency
----------

Because SHMIG is just a shell script it's not a speed champion.
Every time a statement is executed new client process is spawned.
I didn't experience much issues with speed, but if you'll have then
please file an issue and maybe I'll get to that in detail.

Usage with Docker
-----------------
Shmig can be used and configured with env vars
```
docker run -e PASSWORD=root -e HOST=mariadb -v $(pwd)/migrations:/sql --link mariadb:mariadb mkbucc/shmig:latest -t mysql -d db-name up
```

This will attempt 3 retries of the command before exiting. This can 
be useful in a docker-compose set up where the SHMIG container `depends_on`
another DB service within the docker-compose configuration.
 

OS Packaging
------------

A [Debian](https://www.debian.org) package is available for shmig
at https://packages.kaelshipman.me.

[NixOS](https://nixos.org/) supports `shmig` on Linux and Darwin at the moment, the package can be
installed into the user's profile by running `nix-env -iA nixos.shmig` since
[18.03](https://nixos.org/nixos/manual/release-notes.html#sec-release-18.03).

*Contributions for other systems would be greatly welcomed, and can be submitted via PR to this repo.

Todo
----

  1. Speed. Some optimizations are definitely possible to speed things up.
  2. A way to spawn just one CLI client. Maybe something with FIFOs and SIGCHLD handler.
  3. Better documentation :\

