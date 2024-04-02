#!/bin/bash
set -x


. ./functions

OUT1=outputs/attack/attackvarytest.csv

victimSizes=(32 64 128 192 256 320)
victimIterations=10000
victimTypes=read

attackSize=128

slowdowns=()
window=0
windowSize=10

index=0
for victimSize in ${victimSizes[@]}; do
    slowdowns[$index]+="$victimSize "
    slowdowns[$index]+="1.00 "

    #1Attacker
    for ((test=1; test<=$windowSize; test++)); do
	BwReadVictimSolo $victimSize $victimIterations

    	BkPLLWriteAttackersVary $attackSize 1 1
    	sleep 5
    	BwReadVictimCorun $victimSize $victimIterations
	window=$(echo $window+$slowdown | bc)
    	killall BkPLL
    	wait &> /dev/null

    	#index=$((index+1))
	sleep 3
    done

    window=$(echo "scale=2; $window/$windowSize" | bc)
    slowdowns[$index]+="$window "
    window=0

    #2Attacker
    for ((test=1; test<=$windowSize; test++)); do
	BwReadVictimSolo $victimSize $victimIterations

    	BkPLLWriteAttackersVary $attackSize 1 2
    	sleep 5
    	BwReadVictimCorun $victimSize $victimIterations
	window=$(echo $window+$slowdown | bc)
    	killall BkPLL
    	wait &> /dev/null

    	#index=$((index+1))
	sleep 3
    done

    window=$(echo "scale=2; $window/$windowSize" | bc)
    slowdowns[$index]+="$window "
    window=0

    #3Attacker
    for ((test=1; test<=$windowSize; test++)); do
	BwReadVictimSolo $victimSize $victimIterations

    	BkPLLWriteAttackersVary $attackSize 1 3
    	sleep 5
    	BwReadVictimCorun $victimSize $victimIterations
	window=$(echo $window+$slowdown | bc)
    	killall BkPLL
    	wait &> /dev/null

    	#index=$((index+1))
	sleep 3
    done

    window=$(echo "scale=2; $window/$windowSize" | bc)
    slowdowns[$index]+="$window "
    window=0    
    
    index=$((index+1))

    #sleep 3
done

#Clear output file
> $OUT1

echo "WSS,Solo,1Attacker,2Attacker,3Attacker" >> $OUT1

#printf '%s\n' "${slowdowns[@]}" | paste -sd ',' >> $OUT1

for out in "${slowdowns[@]}"; do
    printf '%s\n' $out | paste -sd ',' >> $OUT1
done
