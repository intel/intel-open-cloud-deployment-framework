#!/bin/bash

source ${OPS_VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

echo "Deleting all VMs"
openstack server list | grep test* |awk '{print $2}' | xargs openstack server delete

existed=`openstack server list`
if [ "${existed}x" != "x" ]; then
    echo "$existed" | awk 'NR>3'| grep "|" | cut -d '|' -f 2 | while read line
    do
        echo "openstack server delete $line"
        openstack server delete $line
    done
fi

# Show remaining servers
echo "Show remaining servers

rc_array=(server)
for item in ${rc_array[@]}
do
    echo
    echo "openstack ${item} list"
    existed=`openstack ${item} list`
    if [ "${existed}x" == "x" ]; then
        echo "Empty"
    else
        echo "$existed"
    fi
    echo
done
