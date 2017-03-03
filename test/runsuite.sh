#! /bin/sh -e
# Run shmig tests against a database server.

source report.sh

[ "x$1" = "x" ] && printf "usage: %s <testsuite>\n" $(basename $0) >&2 && exit 1

SUITE=$1
case $SUITE in
	sqlite3*)
		E=sqlite3_stderr.out
		rm -f ./sql/test.db
		;;
	mysql*)
		V=mysql:8
		N=mysql-server
		E=mysql_stderr.out
		trap "printf \"error: \" >&2; [ -f $E ] && cat $E>&2 || echo \"shutting down server\"; docker stop $N ; docker rm $N" ERR
		docker run -d -p 127.0.0.1:3306:3306 --name $N -e MYSQL_ALLOW_EMPTY_PASSWORD=True $V
		STARTUP_TIMEOUT_IN_SECONDS=100
		;;
	psql*)
		V=postgres:9.6-alpine
		N=postgres-server
		E=psql_stderr.out
		trap "printf \"error: \" >&2; [ -f $E ] && cat $E>&2 || echo \"shutting down server\"; docker stop $N ; docker rm $N" ERR
		docker run -d -p 127.0.0.1:5432:5432 --name $N -e POSTGRES_PASSWORD=postgres $V
		STARTUP_TIMEOUT_IN_SECONDS=50
		;;
	*)
		printf "unknown suite %s\n" $SUITE >&2
		exit 1
		;;
esac


#-----------------------------------------------------------------------------
#
#                       W A I T   F O R   S E R V E R
#
#-----------------------------------------------------------------------------

case $SUITE in
	mysql|psql)
		printf "Waiting %d seconds for %s server to start up in docker container " $STARTUP_TIMEOUT_IN_SECONDS $V
		STARTED=0
		RETRIES=0
		while [ $STARTED -eq 0 ] && [ $RETRIES -lt $STARTUP_TIMEOUT_IN_SECONDS ] ; do
			printf "."
			sleep 1
			RETRIES=$((RETRIES + 1))
			case $SUITE in
				mysql)
					echo "SELECT 1" | mysql -u root -h 127.0.0.1 -P 3306 -D mysql >mysql_startup.log 2>&1 && STARTED=1
					;;
				psql)
					PGPASSWORD=postgres psql -h localhost -U postgres -c "SELECT 1" -d postgres > psql_startup.log 2>&1 && STARTED=1
					;;
				*)
					printf "logic error, suite = %s\n" $SUITE >&2
					exit 1
					;;
			esac
		done
		if [ $RETRIES -lt $STARTUP_TIMEOUT_IN_SECONDS ]
		then
			printf " started.\n"
		else
			printf "error: server didn't start in %d seconds, shutting down server.\n" $STARTUP_TIMEOUT_IN_SECONDS >&2
			docker  stop  $N
			docker  rm    $N
			exit 1
		fi
		;;
	*)
		#
		# EMPTY
		#
		;;
esac

#-----------------------------------------------------------------------------
#
#                              R U N   T E S T S
#
#-----------------------------------------------------------------------------

report_start $SUITE

F=$(report_filename $SUITE)

rm -f $F

while IFS= read -r cmd ; do

	printf "\n%s\n---------------\n" "$cmd" >> $F

	case $SUITE in
		sqlite3)
			../shmig -m ./sql -d ./sql/test.db -t sqlite3 $cmd >> $F 2>sqlite3_stderr.out
			;;
		mysql)
			../shmig -m ./sql -l root -t mysql -d mysql -H 127.0.0.1 -P 3306 $cmd >> $F 2>$E
			;;
		psql)
			../shmig -m ./sql -t postgresql -d postgres -l postgres -p postgres -H localhost -P 5432 $cmd >> $F 2>psql_stderr.out
			;;
		*)
			printf "logic error, shouldn't get here: unknown suite %s\n" $SUITE >&2
			exit 1
			;;
	esac

done < test_commands

# XXX: If test fails, trap doesn't fire and server is not shut down.
report_result $SUITE



#-----------------------------------------------------------------------------
#
#                       S H U T   D O W N   S E R V E R
#
#-----------------------------------------------------------------------------

case $SUITE in
	mysql|psql)
		printf "Shutting down %s server ...\n" $V
		docker  stop  $N
		docker  rm    $N
		;;
	*)
		#
		# EMPTY
		#
		;;
esac
