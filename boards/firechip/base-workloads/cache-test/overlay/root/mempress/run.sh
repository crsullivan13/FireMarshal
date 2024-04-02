#!/bin/bash

set -euo pipefail

accessType=$1 #sr (strided read),sw,rr (random read),rw

for i in 2 3; do taskset -c $i ./mempress-rocc.riscv -a $accessType -x -s 128 -i 10000000 &> /dev/null & done ; BkPLL -c 1 -l 6 -b 0x40 -m 128 -x -e 0 -i 15000