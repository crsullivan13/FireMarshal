#!/bin/bash

set -euo pipefail

#assumes quad core system
#assumes two banks

chmod +x BothBankBw.sh SingleBankBw.sh

for i in 1 2 3 4; do ./SingleBankBw.sh 0 $i ; done
cat outputs/bw/singlebank* | grep -i sum | awk 'NF{print $(NF)}' > outputs/bw/singlebankbw-c1234-bank0.sh

sleep 2

for i in 1 2 3 4; do ./BothBankBw.sh $i ; done
cat outputs/bw/bothbank* | grep -i sum | awk 'NF{print $(NF)}' > outputs/bw/bothbankbw-c1234-bank0.sh