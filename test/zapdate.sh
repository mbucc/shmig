#! /bin/sh -e
# Convert any dates in shmig output to the string "*now*"

sed 's/20..-[012].-[0123]. ..:..:..\(\.[0-9]*\)*/*now*/'
