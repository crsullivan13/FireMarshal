#!/bin/bash
set -x


. ./functions

OUT1=../output/hangtest.csv

#Clear output file
> $OUT1

echo "MaxAccesses" >> $OUT1

maxAccesses=(8 9 10 11 12 13 14 15 16 )
accessWindow=$1
victimIterations=10000

bw=()

index=0
for maxAcc in ${maxAccesses[@]}; do
    bw[$index]+="$maxAcc "

    . ./set.sh $accessWindow $maxAcc

    BkPLLWriteAttackers 2 64 1
    sleep 1.5
    killall BkPLL

    printf '%s\n' ${bw[$index]} | paste -sd ',' >> $OUT1
    index=$((index+1))
    #echo "$index"

    . ./unset.sh

    sleep 1.5
done

for ((i=0; i<${#bw[@]}; i++)); do
    printf '%s\n' ${bw[$i]} | paste -sd ',' >> $OUT1
done
