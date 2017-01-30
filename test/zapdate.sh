#! /bin/sh -e
# Convert any dates in shmig output to current_time.

sed 's/20[1-9][0-9]-[02][0-9]-[123][0-9] [012][0-9]:[0-5][0-9]:[0-5][0-9]\(\.[0-9]*\)*/current_time/'
