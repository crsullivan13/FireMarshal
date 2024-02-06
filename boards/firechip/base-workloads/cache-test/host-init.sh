#!/bin/bash

echo "Building dos tests"
cd overlay/root/Attacks/workloads

make

cd ../../../..

echo "Building address mapper"
cd overlay/root/palloc

make mc-mapping-pagemap

cd ../../..

echo "Building hpm-counter binary"
cd overlay/root/riscv-hpmcounters/

make

cd ../../../
