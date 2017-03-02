#! /bin/sh -e
# Run SQL in psql directory against PostresSQL in a docker container.

# XXX: Specify IP of Docker's bridge nework when starting MySQL server container.
# XXX: poll instead of sleep

trap 'printf "error, shutting down PostgreSQL server ...\n" >&2; docker stop shmig-psql-test ; docker rm shmig-psql-test' ERR

printf "Starting PostgreSQL server container ...\n" >&2
docker run -d --name shmig-psql-test -e POSTGRES_PASSWORD=postgres postgres:9.6

# Wait for PostresSQL server to start.
N=15
printf "Waiting %d seconds for PostresSQL to start up ...\n" $N >&2
sleep $N

source common.sh

IFS=$(printf "\n\b")
for c in $COMMANDS; do

	printf "\n%s\n---------------\n" $c

	# Many of defaults from Docker file are used.
	docker run -it --link shmig-psql-test:psql -v $(pwd)/sql:/sql mkbucc/shmig -t postgresql -d postgres -l postgres -p postgres -H 172.17.0.2 -P 5432 "$c"

	# There is some race condition in running docker in a tight loop like this.
	# The script fails regularly but intermittenly.  Try a sleep to at least
	# make behavior consistent.
	sleep 1

done

printf "Shutting down PostreSQL server ...\n" >&2
printf "stop ... " >&2 ; docker  stop  shmig-psql-test >&2
printf "rm ...   " >&2 ; docker  rm    shmig-psql-test >&2
