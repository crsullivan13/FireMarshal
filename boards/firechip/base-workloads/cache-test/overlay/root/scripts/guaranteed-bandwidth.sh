#!/bin/bash

# NOTE: If getting firmware trap errors, remove output redirects and manually inspect uartlog for data

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/workload-setup.sh"
 
LOGDIR="/root/outputs/guaranteed"
mkdir -p "$LOGDIR"
 
TYPES=("read" "write")
CORES=(1 2 3 4)
DURATION=5
 
for type in "${TYPES[@]}"; do
    for cores in "${CORES[@]}"; do
        run_dir="$LOGDIR/${type}/run_${cores}_cores"
        mkdir -p "$run_dir"
 
        echo "=== Starting: type=$type cores=$cores (logs -> $run_dir) ==="
 
        # start one pll per core id: 0 .. cores-1
        for ((c=0; c<cores; c++)); do
            logfile="$run_dir/pll_c${c}.log"
            BkPLL -c $c -e 0 -l 6 -m 32768 -i 9999999999999 -b 0xe00 -a "$type" -x > "$logfile" 2>&1 &
        done
 
        echo "Running for ${DURATION}s..."
        sleep "$DURATION"
 
        echo "Sending SIGINT to all pll processes..."
        killall -2 BkPLL || true
 
        sleep 5
    done
done
 
echo "All experiments completed."

sleep 5