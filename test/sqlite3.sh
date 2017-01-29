#! /bin/sh -e
# Run SQL in sqlite3 directory against SQLite3.

rm -f ./sqlite3/test.db

COMMANDS="
up steps=1
status
rollback
pending
migrate
down till=1485648520
status
pending
"

IFS=$(printf "\n\b")
for c in $COMMANDS; do

	printf "\n%s\n---------------\n" $c

	docker run -v $(pwd)/sqlite3:/sql mkbucc/shmig -d /sql/test.db -t sqlite3 "$c"

done
