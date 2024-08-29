#!/bin/bash

echo "Building synth workloads"
cd overlay/root/workloads

make

cd ../../../

# echo "Building address mapper"
# cd overlay/root/palloc

# make mc-mapping-pagemap

# cd ../../../

echo "Building mempress"
cd overlay/root/mempress/

make

cd ../../../

echo "Building reg code"
cd overlay/root/reg/

make

cd ../../../
