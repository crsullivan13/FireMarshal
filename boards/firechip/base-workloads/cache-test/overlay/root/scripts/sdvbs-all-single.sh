#!/bin/bash

set -euo pipefail

workloads=(disparity localization mser sift stitch svm tracking)


for type in ${workloads[@]}; do
    sleep 0.5
    taskset -c 1 ./sdvbs-cif.sh $type | grep -i cycles | awk 'NF{print $(NF)}' >> /root/outputs/sdvbs/$type-single.txt
done