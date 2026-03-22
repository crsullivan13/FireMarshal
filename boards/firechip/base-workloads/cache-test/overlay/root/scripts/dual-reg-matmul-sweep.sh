#!/bin/bash

# 53 160 480 - DRAM
# 1280 2560 5120 - LLC

OUT0="opt0.txt"
OUT1="opt1.txt"

run_pair() {
    local mode="$1"
    local redirect="$2"

    if [ "$redirect" = "truncate" ]; then
        echo "$mode" > "$OUT0"
        taskset -c 0 ./matrix -a 0 -n 756 >> "$OUT0"
        echo "$mode" > "$OUT1"
        taskset -c 0 ./matrix -a 1 -n 756 >> "$OUT1"
    else
        echo "$mode" >> "$OUT0"
        taskset -c 0 ./matrix -a 0 -n 756 >> "$OUT0"
        echo "$mode" >> "$OUT1"
        taskset -c 0 ./matrix -a 1 -n 756 >> "$OUT1"
    fi
}

set_cbqri() {
    local llc_period="$1"
    local llc_access="$2"
    local dram_access="$3"
    ./scripts/cbqri-setup.sh "$llc_period" "$llc_access" "$dram_access"
}

run_labeled_pair() {
    local label="$1"
    run_pair "$label" "append"
}

touch "$OUT0"
touch "$OUT1"

run_pair "isol" "truncate"

# LLC
set_cbqri 50 1 831
echo 1 > /sys/kernel/debug/cbqri/cache_bandwidth/global_enable
echo 1 > /sys/kernel/debug/cbqri/mem_bandwidth/global_enable
run_labeled_pair "llc-1280-dram-53"

set_cbqri 50 1 2500
run_labeled_pair "llc-1280-dram-160"

set_cbqri 50 1 7500
run_labeled_pair "llc-1280-dram-480"

set_cbqri 25 1 831
run_labeled_pair "llc-2560-dram-53"

set_cbqri 25 1 2500
run_labeled_pair "llc-2560-dram-160"

set_cbqri 25 1 7500
run_labeled_pair "llc-2560-dram-480"

set_cbqri 12 1 831
run_labeled_pair "llc-5333-dram-53"

set_cbqri 12 1 2500
run_labeled_pair "llc-5333-dram-160"

set_cbqri 12 1 7500
run_labeled_pair "llc-5333-dram-480"

# DRAM
set_cbqri 50 1 831
run_labeled_pair "llc-1280-dram-53"

set_cbqri 25 1 831
run_labeled_pair "llc-2560-dram-53"

set_cbqri 13 1 831
run_labeled_pair "llc-5333-dram-53"

set_cbqri 50 1 2500
run_labeled_pair "llc-1280-dram-160"

set_cbqri 25 1 2500
run_labeled_pair "llc-2560-dram-160"

set_cbqri 13 1 2500
run_labeled_pair "llc-5333-dram-160"

set_cbqri 50 1 7500
run_labeled_pair "llc-1280-dram-480"

set_cbqri 25 1 7500
run_labeled_pair "llc-2560-dram-480"

set_cbqri 12 1 7500
run_labeled_pair "llc-5333-dram-480"
