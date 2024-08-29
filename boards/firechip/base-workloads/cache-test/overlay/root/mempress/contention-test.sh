#!/bin/bash

set -euo pipefail

. ./functions

accessType=$1 #sr (strided read),sw,rr (random read),rw
attackItrs=$2 #should be higher when not throttling, lower when throttling
victimBank=$3
mask=$4
stride=$5
#OUT=$6


# Start the mempress processes in the background and add them to the cgroup
(
    echo $$ > /sys/fs/cgroup/palloc/part2/cgroup.procs
    for i in 1 2; do
        (
            echo $$ > /sys/fs/cgroup/palloc/part2/cgroup.procs
            taskset -c $i ./mempress-rocc.riscv -m 64 -a $accessType -s $stride -i $attackItrs -b $mask -e 0 &
        )
    done
    wait
) &

# Start the BkPLL process in the background and add it to the cgroup
(
    echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs
    BkPLL -c 0 -l 6 -b $mask -m 128 -e $victimBank -i 15000 | grep bandwidth | awk 'NF{print $(NF-1)}' > ../outputs/synth-attack/bkpll-victim.txt &
    wait $!
) &

# Wait for all background processes to finish
wait