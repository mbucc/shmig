all_tests: smoketest

#------------------------------------------------------------------------------
#
#                              S M O K E T E S T
#
#  Run the shmig script in parent directory against each backend, using same 
#  set of commands, stored in test_commands file.  The migrations directory
#  holding the SQL for the tests is the in sql subdirectory.
#------------------------------------------------------------------------------
.PHONY: smoketest
smoketest:
	./sqlite3.sh
	./psql.sh
	./mysql.sh

.PHONY: clean
clean:
	rm -f *_stderr.out
	rm -f *_actual.txt
	rm -f *startup.log
	rm -f *_tmp.txt
