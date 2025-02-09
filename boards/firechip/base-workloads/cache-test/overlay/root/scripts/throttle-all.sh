#!/bin/bash
#this is for attacker vs. victim tests
#puts attackers in one domain

set -euo pipefail
window=$1
maxReads=$2
maxWrites=$3
devmem 0x20000000 32 0
devmem 0x20000008 32 $window
devmem 0x2000000c 32 $maxReads
devmem 0x2000001c 32 $maxWrites
devmem 0x2000003c 32 0xfffffffe
devmem 0x20000040 32 0xffffffff
devmem 0x20000044 32 0xffffffff
devmem 0x2000004C 32 0
devmem 0x20000050 32 0
devmem 0x20000054 32 0
devmem 0x20000058 32 0
devmem 0x2000005C 32 0
devmem 0x20000060 32 0
devmem 0x20000064 32 0
devmem 0x20000068 32 0
devmem 0x2000006C 32 0
devmem 0x20000070 32 0
devmem 0x20000074 32 0
devmem 0x20000078 32 0
devmem 0x2000007C 32 0
devmem 0x20000080 32 0
devmem 0x20000084 32 0
devmem 0x20000088 32 0
devmem 0x2000008C 32 0
devmem 0x20000090 32 0
devmem 0x20000094 32 0
devmem 0x20000098 32 0
devmem 0x2000009C 32 0
devmem 0x200000A0 32 0
devmem 0x200000A4 32 0
devmem 0x200000A8 32 0
devmem 0x200000AC 32 0
devmem 0x200000B0 32 0
devmem 0x200000B4 32 0
devmem 0x200000B8 32 0
devmem 0x200000BC 32 0
devmem 0x200000C0 32 0
devmem 0x200000C4 32 0
devmem 0x200000C8 32 0
devmem 0x200000CC 32 0
devmem 0x200000D0 32 0
devmem 0x200000D4 32 0
devmem 0x200000D8 32 0
devmem 0x200000DC 32 0
devmem 0x200000E0 32 0
devmem 0x200000E4 32 0
devmem 0x200000E8 32 0
devmem 0x200000EC 32 0
devmem 0x200000F0 32 0
devmem 0x200000F4 32 0
devmem 0x200000F8 32 0
devmem 0x200000FC 32 0
devmem 0x20000100 32 0
devmem 0x20000104 32 0
devmem 0x20000108 32 0
devmem 0x2000010C 32 0
devmem 0x20000110 32 0
devmem 0x20000114 32 0
devmem 0x20000118 32 0
devmem 0x2000011C 32 0
devmem 0x20000120 32 0
devmem 0x20000124 32 0
devmem 0x20000128 32 0
devmem 0x2000012C 32 0
devmem 0x20000130 32 0
devmem 0x20000134 32 0
devmem 0x20000138 32 0
devmem 0x2000013C 32 0
devmem 0x20000140 32 0
devmem 0x20000144 32 0
devmem 0x20000148 32 0
devmem 0x2000014C 32 0
devmem 0x20000150 32 0
devmem 0x20000154 32 0
devmem 0x20000000 32 1
