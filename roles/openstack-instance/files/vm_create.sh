#!/bin/bash

source ${OPS_VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

for index in $(seq 1 ${OPS_VM_NUM}); do
    openstack server create --image ${OPS_VM_IMAGE} --flavor ${OPS_VM_FLAVOR} \
        --key-name ${OPS_VM_KEY} --network ${OPS_VM_NETWORK} \
        --user-data ${OPS_VM_UD_PATH} ${OPS_VM_NAME}-${index}
done
