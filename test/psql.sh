#! /bin/sh -e
# Run SQL in psql directory against PostresSQL in a docker container.

trap 'printf "Shutting down PostgreSQL server ...\n" ; docker stop shmig-psql-test ; docker rm shmig-psql-test' ERR

# TODO: Specify IP of Docker's bridge nework.
docker run -d --name shmig-psql-test -e POSTGRES_PASSWORD=postgres postgres:9.6

# Wait for PostresSQL server to start.
# TODO: poll with psqlclient instead of sleeping
N=15
printf "Waiting %d seconds for PostresSQL to start up ...\n" $N
sleep $N

source common.sh

IFS=$(printf "\n\b")
for c in $COMMANDS; do

	printf "\n%s\n---------------\n" $c

	# Many of defaults from Docker file are used.
	docker run -it --link shmig-psql-test:psql -v $(pwd)/sql:/sql mkbucc/shmig -t postgresql -d postgres -l postgres -p postgres -H 172.17.0.2 -P 5432 "$c"

done

printf "Shutting down PostreSQL server ...\n"
printf "stop ... " ; docker  stop  shmig-psql-test
printf "rm ...   " ; docker  rm    shmig-psql-test
