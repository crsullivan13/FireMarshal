#!/bin/bash
set -x

. ./functions

OUT1=outputs/solobru.csv

victimSizes=(64 64 64 64 64 64 64 64 64 64)
victimIterations=10000
victimTypes=read
victimCore=0
victimBank=0

attackerSize=64

bwReg=()

index=0
for victimSize in ${victimSizes[@]}; do
    bwReg[$index]+="$victimSize "

    source unset.sh

    BkPLLSoloBw $victimCore $victimSize $victimTypes $victimIterations $victimBank
    bwReg[$index]+="$solo "

    source set.sh 426 4

    BkPLLSoloBw $victimCore $victimSize $victimTypes $victimIterations $victimBank
    bwReg[$index]+="$solo "

    source unset.sh

    index=$((index+1))
    echo "$index"

    sleep 3
done

> $OUT1

echo "WSS,unreg,reg" >> $OUT1

for ((i=0; i<${#bwReg[@]}; i++)); do
    printf '%s\n' ${bwReg[$i]} | paste -sd ',' >> $OUT1
done