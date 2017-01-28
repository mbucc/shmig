#! /bin/sh -e
# Run SQL in migrations directory against SQLite3.

docker run -v $(pwd)/sqlite3:/sql mkbucc/shmig -d test.db -t sqlite3 up
