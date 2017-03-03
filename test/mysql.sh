#! /bin/sh -e
# Run shmig tests against MySQL server in a docker container.

source report.sh

V=mysql:8
N=mysql-server
E=mysql_stderr.out


# If an error occurs, shutdown server.
trap "printf \"error: \" >&2; [ -f $E ] && cat $E>&2 || echo \"shutting down server\"; docker stop $N ; docker rm $N" ERR



#-----------------------------------------------------------------------------
#
#                  S T A R T   U P   M Y S Q L   S E R V E R 
# 
#-----------------------------------------------------------------------------

docker run -d -p 127.0.0.1:3306:3306 --name $N -e MYSQL_ALLOW_EMPTY_PASSWORD=True $V

MAX_RETRIES=100
printf "Waiting %d seconds for %s server to start up in docker container " $MAX_RETRIES $V
STARTED=0
RETRIES=0
while [ $STARTED -eq 0 ] && [ $RETRIES -lt $MAX_RETRIES ] ; do
	printf "."
	sleep 1
	RETRIES=$((RETRIES + 1))
	echo "SELECT 1" | mysql -u root -h 127.0.0.1 -P 3306 -D mysql >mysql_startup.log 2>&1 && STARTED=1
done
if [ $RETRIES -lt $MAX_RETRIES ] 
then
	printf " started.\n"
else
	printf "error: server didn't start in %d seconds, shutting down server.\n" $MAX_RETRIES >&2
	docker  stop  $N
	docker  rm    $N
	exit 1
fi



#-----------------------------------------------------------------------------
#
#                              R U N   T E S T S 
# 
#-----------------------------------------------------------------------------

report_start mysql

F=$(report_filename mysql)

rm -f $F

while IFS= read -r cmd ; do

	printf "\n%s\n---------------\n" "$cmd" >> $F

	../shmig -m ./sql -l root -t mysql -d mysql -H 127.0.0.1 -P 3306 $cmd >> $F 2>$E

done < test_commands

# XXX: If test fails, trap doesn't fire and server is not shut down.
report_result mysql



#-----------------------------------------------------------------------------
#
#                       S H U T   D O W N   S E R V E R 
# 
#-----------------------------------------------------------------------------

printf "Shutting down %s server ...\n" $V
docker  stop  $N
docker  rm    $N
