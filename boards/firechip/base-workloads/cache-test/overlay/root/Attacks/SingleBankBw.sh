#!/bin/bash

set -euo pipefail

OUT=outputs/bw/singlebankbw-c$2-bank$1.csv
> $OUT

wss=128
iterations=30000
bank=$1
options="-x -l 6 -e $bank -b 0x40 -i $iterations -m $wss"

numcores=$2
sum=0
bandwidth=()

temp_dir=$(mktemp -d)

for ((i=0;i<numcores;i++)); do
	BkPLL -c $i $options > "$temp_dir/core_${i}_output.txt" & pid=$!
	pids[$i]=$pid
done

for pid in ${pids[*]}; do
	wait $pid
done

for ((i=0;i<numcores;i++)); do
	output=$(<"$temp_dir/core_${i}_output.txt")
	bandwidth[$i]=$(echo "$output" | grep bandwidth | awk 'NF{print $(NF-1)}')
done

for ((i=0;i<numcores;i++)); do
	echo "CORE $i: ${bandwidth[$i]}" >> $OUT
	sum=$(echo $sum+${bandwidth[$i]} | bc)
done
echo "SUM: $sum" >> $OUT

rm -rf "$temp_dir"
