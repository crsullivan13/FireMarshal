#!/bin/bash
set -x

. ./functions

OUT1=../output/hangtest.csv

#Clear output file
> $OUT1

echo "MaxAccesses,SoloBandwidth,ContestedBandwidth" >> $OUT1

maxAccesses=(1 2 3 4 5)
accessWindow=$1
victimIterations=10000

bw=()

index=0
for maxAcc in ${maxAccesses[@]}; do
    bw[$index]+="$maxAcc "

    . ./set.sh $accessWindow $maxAcc

    BkPLLSolo 3 64 read $victimIterations 1
    bw[$index]+="$solo "

    BkPLLWriteAttackers 3 64 1
    sleep 1.5
    BkPLLSoloCorun 3 64 read $victimIterations 1
    bw[$index]+="$slow "
    killall BkPLL

    #printf '%s\n' ${bw[$index]} | paste -sd ',' >> $OUT1
    index=$((index+1))
    #echo "$index"

    . ./unset.sh

    sleep 1.5
done

for ((i=0; i<${#bw[@]}; i++)); do
    printf '%s\n' ${bw[$i]} | paste -sd ',' >> $OUT1
done
