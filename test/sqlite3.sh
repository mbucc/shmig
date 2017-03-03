#! /bin/sh -e
# Run shmig test SQL against SQLite3.

rm -f ./sql/test.db

source report.sh

report_start sqlite3

F=$(report_filename sqlite3)

rm -f $F

while IFS= read -r cmd ; do

	printf "\n%s\n---------------\n" "$cmd" >> $F

	../shmig -m ./sql -d ./sql/test.db -t sqlite3 $cmd >> $F 2>sqlite3_stderr.out

done < test_commands

report_result sqlite3
