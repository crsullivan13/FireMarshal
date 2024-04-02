#!/bin/bash

#this is a builder for turning regulation on for a range of clients
#assumes all clients go to same domain
#currently doesn't set max writes

set -euo pipefail

base=$1 #base decimal address offset
bound=$2 #howmany addresses do we want to set
domain=$3 #boolean vector to enable bwreg for clients
oneHot1=$4 #should be of form 0x00
oneHot2=$5 #should be of form 0x00
oneHot3=$6 #should be of form 0x00
OUT=$7

printf "#!/bin/bash\n" > $OUT
printf "set -euo pipefail\n" >> $OUT
printf "window=\$1\n" >> $OUT
printf "maxReads=\$2\n" >> $OUT
printf "devmem 0x20000000 32 0\n" >> $OUT #global enable to 0
printf "devmem 0x20000008 32 \$window\n" >> $OUT #set window size
printf "devmem 0x2000000c 32 \$maxReads\n" >> $OUT #set max access per window
printf "devmem 0x2000002c 32 $oneHot1\n" >> $OUT #onehot bwReg enable, each bit is a client
printf "devmem 0x20000030 32 $oneHot2\n" >> $OUT
printf "devmem 0x20000034 32 $oneHot3\n" >> $OUT
for ((i=$base; i<$base+($bound*4); i+=4)); do 
    printf "devmem 0x2000%04X 32 $domain\n" $i >> $OUT #assign clients to a domain
done
printf "devmem 0x20000000 32 1\n" >> $OUT #global enable to 1