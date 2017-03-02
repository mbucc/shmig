#! /bin/sh -
# Remove hash docker outputs to stdout when starting up database server.

egrep -v '^[0-9a-f]{64}$'
