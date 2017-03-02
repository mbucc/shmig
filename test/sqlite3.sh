#! /bin/sh -ex
# Run SQL in sqlite3 directory against SQLite3.

rm -f ./sql/test.db

source common.sh

IFS=$(printf "\n\b")
for c in $COMMANDS; do

	printf "\n%s\n---------------\n" $c

	../shmig -m ./sql -d ./sql/test.db -t sqlite3 "$c"

done
