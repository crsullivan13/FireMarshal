#!/bin/bash

# NOTE: If getting firmware trap errors, remove output redirects and manually inspect uartlog for data

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/fs-setup.sh"
"$DIR/palloc-setup.sh"
"$DIR/workload-setup.sh"
"$DIR/bru-module-setup-forward.sh"
 
LOGDIR="/root/outputs/synthetic"
mkdir -p $LOGDIR

echo 0x8000 > /sys/kernel/debug/palloc/palloc_mask
echo $$ > /sys/fs/cgroup/palloc/part2/cgroup.procs
 
echo "Solo all bank victim"
Bw -c 0 -t 1 -m 2048 > "$LOGDIR/bw_all_solo.log" 2>&1
 
sleep 5
 
TYPES=("read" "write")
 
ITERATIONS=${#TYPES[@]}
NUM_RUNS=5
 
# run single bank attack
for ((i=0; i<ITERATIONS; i++)); do
    for ((r=1; r<=NUM_RUNS; r++)); do
        run_dir="$LOGDIR/run_single_bank_${TYPES[$i]}_${r}"
        mkdir -p "$run_dir"

        echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs

        for c in 1 2 3; do
            BkPLL -c $c -e 0 -l 6 -m 32768 -i 9999999999999 -b 0x8e00 -a ${TYPES[$i]} -x > "$run_dir/pll_c${c}.log" 2>&1 &
        done

        sleep 5

        echo "Single bank attack ${TYPES[$i]} run $r"
        Bw -c 0 -t 1 -m 2048 -f victim > "$run_dir/bw_victim.log" 2>&1

        killall -2 BkPLL

        sleep 5
    done
done
 
sleep 5
 
# run all bank attack
for ((i=0; i<ITERATIONS; i++)); do
    for ((r=1; r<=NUM_RUNS; r++)); do
        run_dir="$LOGDIR/run_all_bank_${TYPES[$i]}_${r}"
        mkdir -p "$run_dir"

        echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs

        for c in 1 2 3; do
            BkPLL -c $c -l 6 -m 4096 -e 0 -i 9999999999999 -b 0x8000 -a ${TYPES[$i]} -x > "$run_dir/pll_c${c}.log" 2>&1 &
        done

        sleep 5

        echo "All bank attack ${TYPES[$i]} run $r"
        Bw -c 0 -t 1 -m 2048 -f victim > "$run_dir/bw_victim.log" 2>&1

        killall -2 BkPLL

        sleep 5
    done
done

poweroff -f