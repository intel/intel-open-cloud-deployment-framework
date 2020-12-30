#!/bin/bash

source ${VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

openstack server create --image ${IMAGE_NAME} --flavor ${FLAVOR_NAME} --key-name mykey --network demo_net --min ${VM_NUM} --max ${VM_NUM} ${COMMON_VM_NAME} --wait
