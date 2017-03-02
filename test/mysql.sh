#! /bin/sh -e
# Run SQL in mysql directory against MySQL in a docker container.

# XXX: Specify IP of Docker's bridge nework.
# XXX: Don't use sleep.


trap 'printf "error, shutting down MySQL server ...\n" >&2; docker stop shmig-mysql-test ; docker rm shmig-mysql-test' ERR

printf "Starting MySQL server container ...\n" >&2
docker run -d --name shmig-mysql-test -e MYSQL_ALLOW_EMPTY_PASSWORD=True mysql:8

trap 'docker stop shmig-mysql-test ; docker rm shmig-mysql-test' ERR

# Wait for MySQL server to start.
N=60
printf "Waiting %d seconds for MySQL to start up ...\n" $N >&2
sleep $N

source common.sh

IFS=$(printf "\n\b")
for c in $COMMANDS; do

	printf "\n%s\n---------------\n" $c

	# Many of defaults from Docker file are used.
	docker run -it --link shmig-mysql-test:mysql -v $(pwd)/sql:/sql mkbucc/shmig -d mysql -H 172.17.0.2 -P 3306 "$c"

done

printf "Shutting down MySQL server ...\n" >&2
printf "stop ... " >&2 ; docker  stop  shmig-mysql-test >&2
printf "rm ...   " >&2 ; docker  rm    shmig-mysql-test >&2
