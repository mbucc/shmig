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
	rm -f *_stderr.out
	rm -f *_actual.txt
	rm -f *startup.log
	rm -f *_tmp.txt
