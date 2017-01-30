all_tests: smoketest

.PHONY: smoketest
smoketest: smoke3 smokep smokem

.PHONY: smoke3
smoke3:
	./sqlite3.sh 2>&1 | ./zapdate.sh > smoke3_actual.txt
	diff -uw smoke_expected.txt smoke3_actual.txt

.PHONY: smokep
smokep:
	./psql.sh 2>&1 | ./zapdate.sh | ./zapstartstop.sh > smokep_actual.txt
	diff -uw smoke_expected.txt smokep_actual.txt

.PHONY: smokem
smokem:
	./mysql.sh 2>&1 | ./zapdate.sh | ./tab2pipe.sh | ./zapstartstop.sh > smokem_actual.txt
	diff -uw smoke_expected.txt smokem_actual.txt

