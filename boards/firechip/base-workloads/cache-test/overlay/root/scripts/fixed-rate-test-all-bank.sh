#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$DIR/mshr-reg-setup.sh"

LOGDIR="/root/outputs"
mkdir -p "$LOGDIR"

# Arrays for each run
PERIODS=(1200 2400 4800 9600 19200 38400 76800 153600 307200 614400 1000000)
BUDGETS=(1 2 4 8 16 32 64 128 256 512 831)

ITERATIONS=${#PERIODS[@]}

run_dir="$LOGDIR/solo"
mkdir -p "$run_dir"

echo 0x8000 > /sys/kernel/debug/palloc/palloc_mask
echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs

Bw -c 0 -t 1 -m 2048 -f victim > "$run_dir/Bw_victim.log" 2>&1

for ((i=0; i<ITERATIONS; i++)); do
  sleep 2

  run=$((i+1))
  run_dir="$LOGDIR/run_${run}"
  mkdir -p "$run_dir"

  PERIOD=${PERIODS[$i]}
  BUDGET=${BUDGETS[$i]}

  echo "=== Run $run / $ITERATIONS: PERIOD=$PERIOD, BUDGET=$BUDGET ==="

  # MMIO setup
  devmem 0x21000000 32 0
  devmem 0x21000008 64 $PERIOD
  devmem 0x21000010 64 $PERIOD
  devmem 0x21000018 64 $BUDGET
  devmem 0x21000050 64 0x2
  devmem 0x21000000 32 1

  echo $$ > /sys/fs/cgroup/palloc/part1/cgroup.procs

  # Start BkPLL jobs
  for c in 1 2 3; do
    BkPLL -c $c -l 6 -b 0x8000 -m 4096 -e 1 -a write -x -i 9999999999 >"$run_dir/BkPLL_c${c}.log" 2>&1 &
  done

  sleep 5

  # Run Bw
  Bw -c 0 -t 1 -m 2048 -f victim >"$run_dir/Bw_victim.log" 2>&1

  echo "Run $run complete"
done

poweroff -f
