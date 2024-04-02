#!/bin/bash

cd Attacks/workloads
mv BkPLL /usr/bin
mv Bw /usr/bin
echo 50 > /proc/sys/vm/nr_hugepages

cd ../..