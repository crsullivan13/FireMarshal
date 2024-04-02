#!/bin/bash

set -euo pipefail

OUT=outputs/bw/bothbankbw-c$1.csv
> $OUT

wss=128
iterations=30000
options="-x -e 0 -e 1 -b 0x40 -l 6 -i $iterations -m $wss"

numcores=$1 #should be equal to max number of cores in the system
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
