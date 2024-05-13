#!/bin/bash

set -euo pipefail

accessType=$1 #sr (strided read),sw,rr (random read),rw
attackItrs=$2 #should be higher when not throttling, lower when throttling
victimBank=$3
mask=$4
stride=$5
OUT=$6

#no idea why, but putting this on one line matters
for i in 2 3; do taskset -c $i ./mempress-rocc.riscv -m 64 -a $accessType -s $stride -i $attackItrs -b $mask -e 0 & done; BkPLL -c 1 -l 6 -b $mask -m 128 -e $victimBank -i 15000 | grep bandwidth | awk 'NF{print $(NF-1)}' > ../outputs/synth-attack/$OUT
