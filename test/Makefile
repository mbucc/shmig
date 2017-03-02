all_tests: smoketest

#------------------------------------------------------------------------------
#
#                              S M O K E T E S T
#
#  Run the shmig docker container against each backend, using same set of 
#  commands.  SQL used in tests is in sql directory.
#------------------------------------------------------------------------------
.PHONY: smoketest smoke3 smokep smokem

smoketest: smoke3 smokep smokem

smoke3:
	./sqlite3.sh > t
	./zapdate.sh < t > smoke3_actual.txt
	diff -uw smoke3_expected.txt smoke3_actual.txt
smokep:
	./psql.sh > t
	./zapdate.sh < t > t1
	./zaphash.sh < t1 > smokep_actual.txt
	diff -uw smokep_expected.txt smokep_actual.txt
	@rm -f t t1
smokem:
	./mysql.sh > t
	./zapdate.sh < t > t1
	./zaphash.sh < t1 > smokem_actual.txt
	diff -uw smokem_expected.txt smokem_actual.txt
	@rm -f t t1 t2

.PHONY: clean
clean:
	rm -f t t1 t2 t3
