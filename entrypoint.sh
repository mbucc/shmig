#!/bin/env bash

export > /shmig.conf

max_retries=3
retry=0
wait=5

while [ $retry -le $max_retries ]
do
    shmig $@

    if [ $? -eq 0 ]
    then
        retry=$max_retries
    else
        let retry++
        let wait=$wait*$retry 
    fi

    if [ $retry -le $max_retries ]
    then
        echo "Retry $retry/$max_retries in $wait seconds..."
        sleep $wait
    fi
done