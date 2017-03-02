#! /bin/sh -
# Remove hash, waiting, stopping, etc. messages from stdout as this varies
# from run to run and will break diff.

egrep -v '(^[0-9a-f]{64}$|^Wai|^Shu|^stop|^rm)'
