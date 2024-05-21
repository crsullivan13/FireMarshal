#!/bin/bash

set -euo pipefail

. ./functions

accessType=$1 #sr (strided read),sw,rr (random read),rw
attackItrs=$2 #should be higher when not throttling, lower when throttling
workload=$3
mask=$4
stride=$5

# Start the BkPLL process in the background and add it to the cgroup
(
    echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs
    taskset -c 1 ../scripts/sdvbs-cif.sh $workload > ../outputs/sdvbs/$workload-victim.txt &
    wait $!
) &

# Start the mempress processes in the background and add them to the cgroup
(
    echo $$ > /sys/fs/cgroup/palloc/part2/cgroup.procs
    for i in 2 3; do
        (
            echo $$ > /sys/fs/cgroup/palloc/part2/cgroup.procs
            taskset -c $i ./mempress-rocc.riscv -m 64 -a $accessType -s $stride -i $attackItrs -b $mask -e 0 &
        )
    done
    wait
) &

# Wait for all background processes to finish
wait

#no idea why, but putting this on one line matters
#for i in 2 3; do taskset -c $i ./mempress-rocc.riscv -a $accessType -s $stride -i $attackItrs -b $mask -e 0 & done; taskset -c 1 ../scripts/sdvbs-cif.sh $workload #> ../outputs/sdvbs/$workload-victim.txt

# SDVBSVictim $workload
# sleep 0.1
# Attackers $accessType $stride $attackItrs $mask

# wait

#(echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs; taskset -c 1 ../scripts/sdvbs-cif.sh $workload &) & (echo $$ > /sys/fs/cgroup/palloc/part2/cgroup.procs; for i in 0; do (echo $$ > /sys/fs/cgroup/palloc/part2/cgroup.procs; taskset -c $i ./mempress-rocc.riscv -m 64 -a $accessType -s $stride -i $attackItrs -b $mask -e 0 &) done; wait) &