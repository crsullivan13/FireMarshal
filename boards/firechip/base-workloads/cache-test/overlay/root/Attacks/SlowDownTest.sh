#!/bin/bash
set -x


. ./functions

OUT1=outputs/base.csv

victimSizes=(64 128 192 256 320)
victimIterations=10000
victimTypes=read

slowdowns=()

index=0
for victimSize in ${victimSizes[@]}; do
    slowdowns[$index]+="$victimSize "

    BwReadVictimSolo $victimSize $victimIterations
    slowdowns[$index]+="1.00 "

    BkPLLWriteAttackers 32 1
    sleep 3
    BwReadVictimCorun $victimSize $victimIterations
    slowdowns[$index]+="$slowdown "
    killall BkPLL

    index=$((index+1))
    #echo "$index"

    sleep 3
done

#Clear output file
> $OUT1

echo "WSS,Solo,Slowdown" >> $OUT1

for ((i=0; i<${#slowdowns[@]}; i++)); do
    printf '%s\n' ${slowdowns[$i]} | paste -sd ',' >> $OUT1
done
