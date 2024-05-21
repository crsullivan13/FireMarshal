#!/bin/bash

cd /root/Attacks/workloads
mv BkPLL /usr/bin
mv Bw /usr/bin

cd /root/reg
mv offon reg-single regulate counters /usr/bin
#echo 50 > /proc/sys/vm/nr_hugepages