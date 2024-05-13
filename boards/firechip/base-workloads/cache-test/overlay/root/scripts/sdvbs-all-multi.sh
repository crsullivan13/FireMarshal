#!/bin/bash

set -euo pipefail

corun=disparity
workloads=(disparity localization mser sift stitch svm tracking)


for type in ${workloads[@]}; do
    sleep 0.5
    taskset -c 0 ./sdvbs-cif.sh disparity | grep -i cycles | awk 'NF{print $(NF)}' >> /root/outputs/sdvbs/$type-corun.txt &
    taskset -c 1 ./sdvbs-cif.sh $type | grep -i cycles | awk 'NF{print $(NF)}' >> /root/outputs/sdvbs/$type-multi.txt
    killall -9 disparity || true
done