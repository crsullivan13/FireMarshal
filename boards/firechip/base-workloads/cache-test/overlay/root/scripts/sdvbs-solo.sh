#!/bin/bash

set -euo pipefail

workload=$1

sleep 0.5
echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs
taskset -c 1 ./sdvbs-cif.sh $workload | grep -i usecs | awk 'NF{print $(NF)}' > /root/outputs/sdvbs/$workload-solo.txt