#!/bin/bash

source ${VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

# Create PMEM flavors
cat /etc/kolla/config/nova/nova-compute.conf |grep "pmem_namespaces"  | awk -F '=' '{print $2 }' | awk -F ',' '{ for (i=1; i<=NF; i++) print $i }' | while read line; do label=`echo $line | awk -F ':' '{print $1}'`; openstack flavor set --property hw:pmem='$label' ${FLAVOR_NAME}; done

for nu in ${VM_NUM}; do
    openstack server create --image ${IMAGE_NAME} --flavor ${FLAVOR_NAME} --key-name ${KEY_NAME} --network ${NETWORK_NAME} ${PMEM_VM_NAME}_${nu}
done
