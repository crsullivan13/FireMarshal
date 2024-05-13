#!/bin/bash
set -euo pipefail
window=$1
maxReads=$2
maxWrites=$3
devmem 0x20000000 32 0
devmem 0x20000008 32 $window
devmem 0x2000000c 32 $maxReads
devmem 0x2000001c 32 $maxWrites
devmem 0x2000003c 32 0xffffffff
devmem 0x20000040 32 0xffffffff
devmem 0x20000044 32 0xffffffff
devmem 0x20000048 32 0
devmem 0x2000004C 32 0
devmem 0x20000000 32 1
