# since: Sun Jul 27 18:52:55 EDT 2014

PREFIX=/usr/local

install: ${PREFIX}/bin/shmig

${PREFIX}/bin/shmig: shmig
	cp $? $@

.PHONY: test lint

test:
	(cd test ; make)

lint:
	shellcheck shmig
