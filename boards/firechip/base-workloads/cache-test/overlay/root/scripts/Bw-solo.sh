#!/bin/bash

set -euo pipefail

OUT=$1

sleep 0.5
Bw -c 0 -m 128 -i 15000 -x | grep B/W | awk 'NF{print $(NF-7)}' > ../outputs/$1