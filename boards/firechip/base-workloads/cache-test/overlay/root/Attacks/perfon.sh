#!/bin/bash

set -euo pipefail

period=$1

devmem 0x20000040 32 1
devmem 0x20000046 32 $period