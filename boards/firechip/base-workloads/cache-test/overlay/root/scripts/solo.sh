#!/bin/bash

set -euo pipefail

victimBank=$1
mask=$2

sleep 0.5
echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs
BkPLL -c 1 -l 6 -b $mask -m 128 -e $victimBank -i 15000 | grep bandwidth | awk 'NF{print $(NF-1)}' > /root/outputs/bkpll-solo.txt
# sleep 0.5
# cd /root/mempress
# taskset -c 1 ./mempress-rocc.riscv -i 10000000 | grep BW | awk 'NF{print $(NF-1)}' > /root/outputs/mempress-solo.txt
# cd /root
# sleep 0.5
# Bw -c 0 -m 128 -i 15000 -x | grep B/W | awk 'NF{print $(NF-7)}' > ../outputs/bw-solo.txt 