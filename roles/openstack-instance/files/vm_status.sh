#!/bin/bash

source ${OPS_VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

ret=`openstack server list | awk 'NR>3' | grep '|' | cut -d '|' -f 4 | \
    sed -e 's/^[ ]*//g' | sed -e 's/[ ]*$//g' | cut -d '|' -f 4 | \
    tr ['\n'] [' '] | tr '[:upper:]' '[:lower:]'`

echo $ret
