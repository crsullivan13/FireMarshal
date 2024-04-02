#!/bin/bash
set -x

. ./functions

OUT1=outputs/attack/sepbanksW-slowdown.csv
OUT2=outputs/attack/sepbanksW-bw.csv

victimSizes=(32 64 128 192 256 320)
victimIterations=100000
victimTypes=read
victimCore=3
victimBank=0

attackerSize=128

slowdowns=()
bw=()

windowSize=10
samewindow=0
diffwindow=0
bwsolo=0
bwdiff=0
bwsame=0

index=0
for victimSize in ${victimSizes[@]}; do
    slowdowns[$index]+="$victimSize "
    slowdowns[$index]+="1.00 "

    bw[$index]+="$victimSize "

    for ((test=1; test<=$windowSize; test++)); do
   	BkPLLSolo $victimCore $victimSize $victimTypes $victimIterations $victimBank
	bwsolo=$(echo $bwsolo+$solo | bc)

    	#Attackers on different bank than victim
    	BkPLLWriteAttackers $attackerSize 1
    	sleep 3
    	BkPLLCorun $victimCore $victimSize $victimTypes $victimIterations $victimBank
    	#slowdowns[$index]+="$slowdown "
	diffwindow=$(echo $diffwindow+$slowdown | bc)
	bwdiff=$(echo $bwdiff+$slow | bc)
    	killall $BKPLL
    	wait &> /dev/null

	sleep 3

	BkPLLSolo $victimCore $victimSize $victimTypes $victimIterations $victimBank

    	#Attackers on same bank as victim
    	BkPLLWriteAttackers $attackerSize $victimBank
    	sleep 3
    	BkPLLCorun $victimCore $victimSize $victimTypes $victimIterations $victimBank
    	#slowdowns[$index]+="$slowdown "
	samewindow=$(echo $samewindow+$slowdown | bc)
	bwsame=$(echo $bwsame+$slow | bc)
    	killall $BKPLL
    	wait &> /dev/null

    	#index=$((index+1))
    	#echo "$index"

    	sleep 3
    done

    samewindow=$(echo "scale=2; $samewindow/$windowSize" | bc)
    diffwindow=$(echo "scale=2; $diffwindow/$windowSize" | bc)
    slowdowns[$index]+="$diffwindow "
    slowdowns[$index]+="$samewindow "

    samewindow=0
    diffwindow=0

    bwsolo=$(echo "scale=2; $bwsolo/$windowSize" | bc)
    bwsame=$(echo "scale=2; $bwsame/$windowSize" | bc)
    bwdiff=$(echo "scale=2; $bwdiff/$windowSize" | bc)
    bw[$index]+="$bwsolo "
    bw[$index]+="$bwdiff "
    bw[$index]+="$bwsame "
    
    bwsolo=0
    bwsame=0
    bwdiff=0

    index=$((index+1))

done

> $OUT1
> $OUT2

echo "WSS,Solo,DiffBank,SameBank" >> $OUT1
echo "WSS,SoloBW,DiffBankBW,SameBankBW" >> $OUT2

for out in "${slowdowns[@]}"; do
    printf '%s\n' $out | paste -sd ',' >> $OUT1
done

for out in "${bw[@]}"; do
    printf '%s\n' $out | paste -sd ',' >> $OUT2
done
