#!/bin/bash

BENCHMARKS=("disparity" "mser" "sift" "stitch" "tracking")
BASE_DIR="cortexsuite/vision/benchmarks"

ITERATIONS=${#BENCHMARKS[@]}

cd "$BASE_DIR"

mkdir -p "../../../../cache-test/overlay/root/sd-vbs/"

for((i=0;i < ITERATIONS; i++)); do

    cd "${BENCHMARKS[$i]}"
    make compile

    mkdir -p "../../../../cache-test/overlay/root/sd-vbs/${BENCHMARKS[$i]}"
    cp -r "data" "Makefile" "../../../../cache-test/overlay/root/sd-vbs/${BENCHMARKS[$i]}"

    cd ..

done