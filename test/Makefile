#------------------------------------------------------------------------------
#
#                                  T E S T
#
#	Run the shmig script in parent directory against each backend.
#
#	The file test_commands contains the sequence of shmig commands
#	we run against each backend.
#
#------------------------------------------------------------------------------
.PHONY: test
test:
	./runsuite.sh sqlite3
	./runsuite.sh psql
	./runsuite.sh mysql

.PHONY: clean
clean:
	rm -f 1.out 2.out
	rm -f stdout.actual stderr.actual
	rm -f *startup.log
