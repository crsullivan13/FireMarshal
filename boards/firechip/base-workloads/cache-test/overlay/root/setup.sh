#!/bin/bash

cd /root/workloads
mv BkPLL /usr/bin
mv Bw /usr/bin

cd /root/reg
mv offon regulate-single regulate-mempress counters /usr/bin
#echo 50 > /proc/sys/vm/nr_hugepages #leave this off b/c PALLOC doesn't work with hugepages