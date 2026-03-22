#!/bin/bash

llc_period="$1"
llc_access="$2"
dram_access="$3"

echo "${llc_period}" > /sys/kernel/debug/cbqri/cache_bandwidth/period_len
echo "${llc_access}" > /sys/kernel/debug/cbqri/cache_bandwidth/bc_bw_alloc
echo 1 0 > /sys/kernel/debug/cbqri/cache_bandwidth/bc_alloc_ctl
echo "${llc_period}" > /sys/kernel/debug/cbqri/cache_bandwidth/bc_bw_alloc
echo 1 1 > /sys/kernel/debug/cbqri/cache_bandwidth/bc_alloc_ctl

echo 1000000 > /sys/kernel/debug/cbqri/mem_bandwidth/period_len
echo "${dram_access}" > /sys/kernel/debug/cbqri/mem_bandwidth/bc_bw_alloc
echo 1 0 > /sys/kernel/debug/cbqri/mem_bandwidth/bc_alloc_ctl
echo 1000000 > /sys/kernel/debug/cbqri/mem_bandwidth/bc_bw_alloc
echo 1 1 > /sys/kernel/debug/cbqri/mem_bandwidth/bc_alloc_ctl
