SHMIG
=====

A database migration tool written in BASH consisting of just one file - [`shmig`](https://github.com/naquad/shmig/blob/master/shmig).


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

See [test/sql](https://github.com/mbucc/shmig/tree/master/test/sql) for a few more examples.

Edit [`sqlite3_up_text()`](https://github.com/naquad/shmig/blob/master/shmig#L361-L368) and [`sqlite3_down_text()`](https://github.com/naquad/shmig/blob/master/shmig#L370-L376)  in script if you don't like the default SQL template.


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

RDMS'es are bundled along with their console clients. MySQL has `mysql`, PostgreSQL has `psql` and SQLite3 has `sqlite3`. And that's it! This is enough for interacting with database in batch mode w/o any drivers or connectors.

Using client options one can make its output suitable for batch processing with standard UNIX text-processing tools (`sed`, `grep`, `awk`, ...). This is enough for implementing simple migration system that will store current schema version information withing database (see [`SCHEMA_TABLE`](https://github.com/naquad/shmig/blob/a814690d5040e6aa8f05f112a8b66db9eedb1d07/shmig.conf.example#L21-L22) variable in [`shmig.conf.example`](https://github.com/naquad/shmig/blob/master/shmig.conf.example)).

Usage
-----

SHMIG tries to read configuration from the configuration file
`shmig.conf` in the current working directory.  A sample configuration
file is [`shmig.conf.example`](https://github.com/naquad/shmig/blob/master/shmig.conf.example).

You can also provide an optional config override file by creating the file `shmig.local.conf`.
This allows you to provide a default configuration which is version-controlled with your project,
then specify a non-version-controlled local config file that you can use to provide
instance-specific config. (An alternative is to use envrionment variables, though some people
prefer concrete files to nebulous environment variables.) This works even with custom config
files specified with the `-c` option.

You can also configure SHMIG from command line, or by using
environmental variables.  The command line settings have higher
priority than configuration files or environment settings.

Required options are:

  1. `TYPE` or `-t` - database type
  2. `DATABASE` or `-d` - database to operate on
  3. `MIGRATIONS` or `-m` - directory with migrations

All other options (see `shmig.conf.example` and `shmig -h`) are not necessary.
To simplify usage you should create `shmig.conf` file in your project root directory and put there configuration then just run `shmig <action> ...` in that directory.

For detailed information see `shmig.conf.example` and `shmig -h`.

Migrations
----------

Migrations are SQL files whose name starts with "`<UNIX TIMESTAMP>-`"
and end with ".sql".  The order that new migrations are applied is
[determined](https://github.com/naquad/shmig/blob/master/shmig#L481)
by the seconds-since-epoch time stamp in the filename, with the
oldest migration going first.

Each migration contains two special markers: `-- ====  UP ====` that marks start of section that will be executed when migration is applied and `-- ==== DOWN ====` that marks start of section that will be executed when migration is reverted.

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

Everything between `-- ==== UP ====` till `-- ==== DOWN ====` will be executed when migration is applied and everything between `-- ==== DOWN ====` till the end of file will be executed when migration is reverted. If migration is missing marker or contents of marker is empty then appropriate action will fail (i.e. if you're trying to revert migration that has no or empty `-- ==== DOWN ====` marker you'll get an error and script won't execute any migrations following script with error). Also note those semicolons terminating statements. They're required because you're basically typing that into your database CLI client.

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

This is very early release. I've tried it with SQLite3, PostgreSQL, MySQL databases and didn't find any bugs. If you find any then please report them along with your migrations (or similar that will allow to reproduce bug), tools versions, detailed description of steps and configuration file (w/o DB credentials).

Security considerations
-----------------------

Password is passed to `mysql` and `psql` via environment variable. This can be a security issue if your system allows other users to read environment of process that belongs to another user. In most Linux distributions with modern kernels this is forbidden. You can check this (on systems supporting /proc file system) like this: `cat /proc/1/env` - if you get permission denied error then you're secure.

Efficiency
----------

Because SHMIG is just a shell script it's not a speed champion. Every time a statement is executed new client process is spawned. I didn't experience much issues with speed, but if you'll have then please file an issue and maybe I'll get to that in detail.

Usage with Docker
-----------------
Shmig can be used and configured with env vars
```
docker run -e PASSWORD=root -e HOST=mariadb -v $(pwd)/migrations:/sql --link mariadb:mariadb mkbucc/shmig:latest -t mysql -d db-name up
```

OS Packaging
------------

Currently, a Debian package is available for shmig at https://packages.kaelshipman.me. You may either download it and install it directly, or add the indicated apt repo (see instructions on website).

Building OS packages for shmig requires the `ks-std-libs` package from the same apt repo (again, you can download it directly [here](https://packages.kaelshipman.me/public/deb/pool/main/k/ks-std-libs/ks-std-libs_0.8.5_all.deb)). Once that's installed, you may build packages by simply running `./pkg-build.sh` from the source of this repo.

At the time of this writing, only a Debian package is available. *Contributions for other systems would be greatly welcomed, and can be submitted via PR to this repo.* At some point, package building will be rolled into `peekaygee` (on github at https://github.com/kael-shipman/peekaygee), but until that happens, documentation for the process is as follows:

### Package Types

Package types (deb, rpm, arch, etc.) are managed by simply adding the corresponding name as a directory under `pkg-src`. For example, to add an rpm package, you would do `mkdir pkg-src/rpm`.

Files that are common to all packages go into a special directory called `pkg-src/generic`. Any files under that directory are automatically copied straight into the corresponding locations in all final packages.

Under the package type directory (including generic), you must then create one or more actual package directories. In this case, I would create `pkg-src/rpm/shmig`, since the package I'm building is called `shmig`, but at some point I might also create a special package just for shmig documentation by creating `pkg-src/*/shmig-docs`.

Once the package directory is created, you'll generally create the control files under it. For debian, this is everything in the DEBIAN directory at package root.

The final step is adding the new package type to `pkg-build.sh`. Opening that file, you'll see three functions, `setup_env`, `place_files` and `build_package`. These three functions are called by the `build` function from the `ks-std-libs/libpkgbuilder.sh` library, which you can read about [here](https://github.com/kael-shipman/ks-std-libs/blob/master/src/usr/lib/ks-std-libs/libpkgbuilder.sh). In short, you won't need to mess with `setup_env`, and you'll need to just add package-specific stuff actions to `place_files` and `build_package` to achieve the end result of a final OS package build into `builddir`.

> 
> NOTE: You should bump the version in the `VERSION` file on every change. This is the source of the OS packages' version information.
> 

Todo
----

  1. Speed. Some optimizations are definitely possible to speed things up.
  2. A way to spawn just one CLI client. Maybe something with FIFOs and SIGCHLD handler.
  3. Better documentation :\

