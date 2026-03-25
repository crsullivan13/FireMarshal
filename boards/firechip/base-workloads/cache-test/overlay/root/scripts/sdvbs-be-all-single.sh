#!/usr/bin/env bash

# NOTE: If getting firmware trap errors, remove output redirects and manually inspect uartlog for data
# NOTE: output files commented out by default, i.e. results in your uartlog

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$DIR/workload-setup.sh"
"$DIR/bru-module-setup-forward-single-core.sh"

Bw -c 0 -t 1 -m 128
Bw -c 0 -t 1 -m 2048

LOGDIR="/root/outputs"
mkdir -p "$LOGDIR"

# Arrays for each run  
WORKLOADS=("disparity" "mser" "sift" "stitch" "tracking")

ITERATIONS=${#WORKLOADS[@]}

NUM_REGULATED_RUNS=${1:-5}

for ((i=0; i<ITERATIONS; i++)); do
  WORKLOAD=${WORKLOADS[$i]}

  run=$((i+1))
  run_dir="$LOGDIR/run_${WORKLOAD}"
  mkdir -p "$run_dir"

  echo "=== Run $run / $ITERATIONS: WORKLOAD=$WORKLOAD ==="

  # MMIO setup
  devmem 0x21000000 32 0
  devmem 0x20000000 64 0

  sleep 2
  # baseline (run once)
  taskset -c 0 /root/sd-vbs/$WORKLOAD/data/fullhd/$WORKLOAD /root/sd-vbs/$WORKLOAD/data/fullhd # > "$run_dir/stats_noreg.log" 2>&1

  devmem 0x21000008 64 1000000
  devmem 0x21000010 64 1000000
  devmem 0x21000018 64 831
  devmem 0x21000000 32 1
  devmem 0x20000000 64 1

  # regulated (run multiple times)
  for ((r=1; r<=NUM_REGULATED_RUNS; r++)); do
    taskset -c 0 /root/sd-vbs/$WORKLOAD/data/fullhd/$WORKLOAD /root/sd-vbs/$WORKLOAD/data/fullhd # > "$run_dir/stats_reg_${r}.log" 2>&1
  done

  echo "Run $run complete"
done

poweroff -f
