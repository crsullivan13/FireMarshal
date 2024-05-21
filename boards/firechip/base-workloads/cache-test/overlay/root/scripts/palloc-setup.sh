#!/bin/bash

# !!!NOTE!!! -- only works if you are using Ubuntu, Build-root doesn't have cgroups enabled

mkdir /sys/fs/cgroup/palloc/part1
mkdir /sys/fs/cgroup/palloc/part2

echo 0x8000 > /sys/kernel/debug/palloc/palloc_mask
echo 4 > /sys/kernel/debug/palloc/alloc_balance
echo 1 > /sys/kernel/debug/palloc/use_palloc

echo 0 > /sys/fs/cgroup/palloc/part1/palloc.bins
echo 1 > /sys/fs/cgroup/palloc/part2/palloc.bins