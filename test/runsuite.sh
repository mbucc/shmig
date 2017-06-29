#! /bin/sh
# Run shmig tests against a database server.

source report.sh

[ "x$1" = "x" ] && printf "usage: %s <testsuite>\n" $(basename $0) >&2 && exit 1

#
#		localhost port that the DB running in Docker listens on.
#

DB_PORT=22000

function stop_docker() {
	docker  stop  $1 >/dev/null 2>&1
	docker  rm    $1 >/dev/null 2>&1
}


DB=$1
case $DB in
	sqlite3*)
		E=sqlite3_stderr.out
		rm -f ./sql/test.db
		;;
	mysql*)
		V=mysql:8
		N=mysql-server
		E=mysql_stderr.out
		stop_docker $N
		docker run -l error -d -p 127.0.0.1:$DB_PORT:3306 --name $N \
				-e MYSQL_ALLOW_EMPTY_PASSWORD=True $V
		if [ $? -ne 0 ] 
		then
			echo "error: failed to start MySQL in Docker"
			exit 1
		fi
		STARTUP_TIMEOUT_IN_SECONDS=100
		;;
	psql*)
		V=postgres:9.6-alpine
		N=postgres-server
		E=psql_stderr.out
		stop_docker $N
		docker run -d -l error -p 127.0.0.1:$DB_PORT:5432  --name $N -e POSTGRES_PASSWORD=postgres $V
		if [ $? -ne 0 ] 
		then
			echo "error: failed to start PostgreSql in Docker"
			exit 1
		fi
				STARTUP_TIMEOUT_IN_SECONDS=50
		;;
	*)
		printf "unknown suite %s\n" $DB >&2
		exit 1
		;;
esac


#-----------------------------------------------------------------------------
#
#                       W A I T   F O R   D B   S E R V E R   T O   S T A R T
#
#-----------------------------------------------------------------------------

case $DB in
	mysql*|psql*)
		printf "Waiting up to %d seconds for %s server to start up in docker container " \
				$STARTUP_TIMEOUT_IN_SECONDS \
				$V
		STARTED=0
		RETRIES=0
		while [ $STARTED -eq 0 ] && [ $RETRIES -lt $STARTUP_TIMEOUT_IN_SECONDS ] ; do
			printf "."
			sleep 1
			RETRIES=$((RETRIES + 1))
			case $DB in
				mysql*)
					echo "SELECT 1" | mysql -u root -h 127.0.0.1 -P $DB_PORT  -D mysql \
							>mysql_startup.log 2>&1 \
							&& STARTED=1
					;;
				psql*)
					PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres \
							-c "SELECT 1" -d postgres -p $DB_PORT \
							> psql_startup.log 2>&1 \
							&& STARTED=1
					;;
				*)
					printf "logic error, suite = %s\n" $DB >&2
					exit 1
					;;
			esac
		done
		if [ $RETRIES -lt $STARTUP_TIMEOUT_IN_SECONDS ]
		then
			printf " started.\n"
		else
			printf "error: server didn't start in %d seconds, shutting down server.\n" \
					$STARTUP_TIMEOUT_IN_SECONDS \
					>&2
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

report_start $DB

F=$(report_filename $DB)

rm -f $F
rm -f *_stderr.out

while IFS= read -r cmd ; do

	printf "\n%s\n---------------\n" "$cmd" >> $F

	case $DB in
		sqlite3)
			../shmig -m ./sql -d ./sql/test.db -t sqlite3 $cmd \
					>> $F 2>>$E
			;;
		mysql)
			../shmig -m ./sql -l root -t mysql -d mysql -H 127.0.0.1 -P $DB_PORT $cmd \
					>> $F 2>>$E
			;;
		psql)
			../shmig -m ./sql -t postgresql -d postgres -l postgres -p postgres \
					-H 127.0.0.1 -P $DB_PORT  $cmd \
					>> $F 2>>$E
			;;
		*)
			printf "logic error, shouldn't get here: unknown suite %s\n" $DB >&2
			exit 1
			;;
	esac

done < test_commands

case $DB in
	mysql | psql)
		stop_docker $N
		;;
	*)
		#	EMPTY
		;;
esac



report_result $DB
