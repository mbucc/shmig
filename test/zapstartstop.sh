#! /bin/sh -
# Remove "start ..." and "stopping ..." log lines from mysql and postgres

egrep -v '(^[0-9a-f]{64}$|^Wai|^Shu|^stop|^rm)'
