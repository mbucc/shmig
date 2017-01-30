#! /bin/sh -e
# Convert tab or pipe before dates to pipe (|) symbol so expected output is matched.
# Expects that zapdates.sh has been run first.

# MySql, by default uses tab as column separator.
# Both SQLite and Postgres use pipe (|) symbol.
sed 's/	current_time/|current_time/'
