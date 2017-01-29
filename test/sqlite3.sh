#! /bin/sh -e
# Run SQL in sqlite3 directory against SQLite3.

rm -f ./sqlite3/test.db

source common.sh

IFS=$(printf "\n\b")
for c in $COMMANDS; do

	printf "\n%s\n---------------\n" $c

	docker run -v $(pwd)/sql:/sql mkbucc/shmig -d /sql/test.db -t sqlite3 "$c"

done
