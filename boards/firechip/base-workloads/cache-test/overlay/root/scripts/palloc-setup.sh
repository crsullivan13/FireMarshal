#!/bin/bash

# mount needed fs
mkdir /sys/fs/cgroup/palloc
mount -t cgroup palloc -o palloc /sys/fs/cgroup/palloc/

mkdir /sys/fs/cgroup/palloc/part1
mkdir /sys/fs/cgroup/palloc/part2

echo 0x8000 > /sys/kernel/debug/palloc/palloc_mask
echo 8 > /sys/kernel/debug/palloc/alloc_balance
echo 1 > /sys/kernel/debug/palloc/use_palloc

echo 0 > /sys/fs/cgroup/palloc/part1/palloc.bins
echo 1 > /sys/fs/cgroup/palloc/part2/palloc.bins
