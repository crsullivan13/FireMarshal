#!/bin/bash
set -x

. ./functions

OUT1=outputs/separation.csv

victimSizes=(64 128 192 256 320)
victimIterations=10000
victimTypes=read
victimCore=0
victimBank=0

attackerSize=64

slowdowns=()

index=0
for victimSize in ${victimSizes[@]}; do
    slowdowns[$index]+="$victimSize "

    BkPLLSolo $victimCore $victimSize $victimTypes $victimIterations $victimBank
    slowdowns[$index]+="1.00 "

    #Attackers on different bank than victim
    BkPLLWriteAttackers $attackerSize 1
    sleep 3
    BkPLLCorun $victimCore $victimSize $victimTypes $victimIterations $victimBank
    slowdowns[$index]+="$slowdown "
    killall $BKPLL
    wait &> /dev/null

    #Attackers on same bank as victim
    BkPLLWriteAttackers $attackerSize $victimBank
    sleep 3
    BkPLLCorun $victimCore $victimSize $victimTypes $victimIterations $victimBank
    slowdowns[$index]+="$slowdown "
    killall $BKPLL
    wait &> /dev/null

    index=$((index+1))
    echo "$index"

    sleep 3
done

> $OUT1

echo "WSS,Solo,DiffBank,SameBank" >> $OUT1

for ((i=0; i<${#slowdowns[@]}; i++)); do
    printf '%s\n' ${slowdowns[$i]} | paste -sd ',' >> $OUT1
done