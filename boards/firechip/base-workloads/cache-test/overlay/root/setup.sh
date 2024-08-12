#!/bin/bash

cd /root/Attacks/workloads
mv BkPLL /usr/bin
mv Bw /usr/bin

cd /root/reg
mv offon pb-reg-single regulate-mempress counters /usr/bin
#echo 50 > /proc/sys/vm/nr_hugepages #leave this off b/c PALLOC doesn't work with hugepages