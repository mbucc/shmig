#! /bin/sh -e
# Run shmig tests against PostresSQL server in a docker container.

source report.sh

V=postgres:9.6-alpine
N=postgres-server

trap "printf \"error, shutting down %s server ...\n\" $V; docker stop $N ; docker rm $N" ERR

docker run -d -p 127.0.0.1:5432:5432 --name $N -e POSTGRES_PASSWORD=postgres $V

printf "Waiting for %s server to start up in docker container " $V
STARTED=0
RETRIES=0
while [ $STARTED -eq 0 ] && [ $RETRIES -lt 100 ] ; do
	printf "."
	sleep 1
	RETRIES=$((RETRIES + 1))
	PGPASSWORD=postgres psql -h localhost -U postgres -c "SELECT 1" -d postgres > psql_startup.log 2>&1 && STARTED=1
done
printf " started.\n"

report_start psql

F=$(report_filename psql)

rm -f $F

while IFS= read -r cmd ; do

	printf "\n%s\n---------------\n" "$cmd" >> $F

	../shmig -m ./sql -t postgresql -d postgres -l postgres -p postgres -H localhost -P 5432 $cmd >> $F 2>psql_stderr.out

done < test_commands

# XXX: If test fails, server is not shut down.
report_result psql

printf "Shutting down %s server ...\n" $V
docker  stop  $N
docker  rm    $N
