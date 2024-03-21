#!/bin/bash

#a test to get basline bandwidths for each level in mem heirarchy

set -x

. ./functions

OUT1=../outpus/bwbase.csv
> $OUT1

echo "Type - WSS, Bandwidth" >> $OUT1

wss=(8 32 2048) #assuming 16KB L1, 1MB L2
iterations=10000

bw=()

index=0
for ws in ${wss[@]}; do
    bw[$index]+="BwRead-$wss "
    BwVictimSolo 0 $wss $iterations read
    bw[$index]+="$solo "
    index=$((index+1))

    bw[$index]+="BwWrite-$wss "
    BwVictimSolo 0 $wss $iterations write
    bw[$index]+="$solo "
    index=$((index+1))

    bw[$index]+="BkPLLReadNoBank-$wss "
    BkPLLSoloNoBank 0 $wss read $iterations
    bw[$index]+="$solo "
    index=$((index+1))

    bw[$index]+="BkPLLWriteNoBank-$wss "
    BkPLLSoloNoBank 0 $wss write $iterations
    bw[$index]+="$solo "
    index=$((index+1))

    bw[$index]+="BkPLLReadBank1-$wss "
    BkPLLSolo 0 $wss read $iterations 1
    bw[$index]+="$solo "
    index=$((index+1))

    bw[$index]+="BkPLLWriteBank1-$wss "
    BkPLLSolo 0 $wss write $iterations 1
    bw[$index]+="$solo "
    index=$((index+1))
done

for ((i=0; i<${#bw[@]}; i++)); do
    printf '%s\n' ${bw[$i]} | paste -sd ',' >> $OUT1
done
