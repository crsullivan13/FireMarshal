#!/bin/bash
set -x

. ./functions

maxAccesses=(1 2 3 4 5 6)
accessWindow=$1

index=0
for maxAcc in ${maxAccesses[@]}; do
    . ./set.sh $accessWindow $maxAcc

    BwWriteAttackers 3 64
    sleep 1.5
    killall Bw

    index=$((index+1))
    #echo "$index"

    . ./unset.sh

    sleep 1.5
done
