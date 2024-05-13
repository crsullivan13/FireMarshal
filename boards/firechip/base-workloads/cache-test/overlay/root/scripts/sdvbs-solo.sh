#!/bin/bash

set -euo pipefail

workload=$1

taskset -c 1 ./sdvbs-cif.sh $workload | grep -i cycles | awk 'NF{print $(NF)}' > /root/outputs/sdvbs/$workload-solo.txt