#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/fs-setup.sh"
"$DIR/palloc-setup.sh"
"$DIR/workload-setup.sh"
 
LOGDIR="/root/outputs/synthetic"
mkdir -p $LOGDIR

echo 0x8000 > /sys/kernel/debug/palloc/palloc_mask
echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs
 
echo "Solo all bank victim"
Bw -c 0 -t 1 -m 2048 > "$LOGDIR/bw_all_solo.log" 2>&1
 
sleep 5
 
TYPES=("read" "write")
 
ITERATIONS=${#TYPES[@]}
 
# run single bank attack
for ((i=0; i<ITERATIONS; i++)); do
    run_dir="$LOGDIR/run_single_bank_${TYPES[$i]}"
    mkdir -p "$run_dir"

    echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs
 
    for c in 1 2 3; do
        BkPLL -c $c -e 1 -l 6 -m 32768 -i 9999999999999 -b 0x78000 -a ${TYPES[$i]} -x > "$run_dir/pll_c${c}.log" 2>&1 &
    done    
 
    sleep 5
 
    echo "Single bank attack ${TYPES[$i]}"
    Bw -c 0 -t 1 -m 2048 > "$run_dir/bw_victim.log" 2>&1
 
    killall -2 BkPLL
 
    sleep 5
done
 
sleep 5
 
# run all bank attack
for ((i=0; i<ITERATIONS; i++)); do
    run_dir="$LOGDIR/run_all_bank_${TYPES[$i]}"
    mkdir -p "$run_dir"

    echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs
 
    for c in 1 2 3; do
        BkPLL -c $c -l 6 -m 4096 -e 1 -i 9999999999999 -b 0x8000 -a ${TYPES[$i]} -x > "$run_dir/pll_c${c}.log" 2>&1 &
    done    
 
    sleep 5
 
    echo "All bank attack ${TYPES[$i]}"
    Bw -c 0 -t 1 -m 2048 > "$run_dir/bw_victim.log" 2>&1
 
    killall -2 BkPLL
 
    sleep 5
done

poweroff -f