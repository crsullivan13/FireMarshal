#!/bin/bash

set -euo pipefail

option=$1

contention=("contention-solo.json" "contention-sepBankR.json" "contention-sameBankR.json" "contention-sepBankW.json" "contention-sameBankW.json" "contention-throttledR.json" "contention-throttledW.json")
budgetSlowdown=("640.json" "1280.json" "2560.json" "5120.json" "7680.json" "10240.json" "12800.json" "15360.json")

sdvbs=("disparity" "mser" "sift" "stitch" "tracking" "svm" "localization")

if [[ $option == "contention" || $option == "all" ]]; then
	for i in "${contention[@]}"; do
		echo "$i"
		sudo ./marshal build $i
		sudo ./marshal install $i
	done
fi

if [[ $option == "synthbudget" || $option == "all" ]]; then
	for i in "${budgetSlowdown[@]}"; do
		echo "$i"
		sudo ./marshal build base-$i
		#sudo ./marshal -v build	2bk-$i
		#sudo ./marshal -v build 4bk-$i

		sudo ./marshal install base-$i
		#sudo ./marshal -v install 2bk-$i
		#sudo ./marshal -v install 4bk-$i
	done
fi

if [[ $option == "disparitybudget" || $option == "all" ]]; then
	for i in "${budgetSlowdown[@]}"; do
		echo "$i"
		sudo ./marshal build disparity-$i

		sudo ./marshal install disparity-$i
	done
fi

if [[ $option == "realworld" || $option == "all" ]]; then
	sudo ./marshal build sdvbs-all.json

	sudo ./marshal install sdvbs-all.json
fi

#if [[  $option == "sdvbsbudget" || $option == "all"  ]]; then
#	for i in "${sdvbs[@]}"; do
#		sudo ./marshal build $i-5120.json
#
#		sudo ./marshal install $i-5120.json
#	done
#fi
