#! /bin/sh -e
# Run SQL in mysql directory against MySQL in a docker container.

# TODO: Specify IP of Docker's bridge nework.
docker run -d --name shmig-mysql-test -e MYSQL_ALLOW_EMPTY_PASSWORD=True mysql:8

trap 'docker stop shmig-mysql-test ; docker rm shmig-mysql-test' ERR

# Wait for MySQL server to start.
# TODO: poll with mysqlclient instead of sleeping
N=60
printf "Waiting %d seconds for MySQL to start up ...\n" $N
sleep $N

source common.sh

IFS=$(printf "\n\b")
for c in $COMMANDS; do

	printf "\n%s\n---------------\n" $c

	# Many of defaults from Docker file are used.
	docker run -it --link shmig-mysql-test:mysql -v $(pwd)/mysql:/sql mkbucc/shmig -d mysql -H 172.17.0.2 -P 3306 "$c"

done

printf "Shutting down MySQL server ...\n"
docker  stop  shmig-mysql-test
docker  rm    shmig-mysql-test
