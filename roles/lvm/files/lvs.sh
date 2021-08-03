#!/bin/bash

SIZE=$LV_SIZE
NUM=$LVS_NUM
dev=$1 ## i.e. /dev/sdb

vg=${dev##*/}vg ## i.e. sdbvg

sudo pvcreate $dev
sudo vgcreate $vg $dev
for k in `seq 1 $NUM`;
do
    sudo lvcreate -n datalv$k -L $SIZE $vg
done
