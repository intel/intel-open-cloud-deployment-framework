#!/bin/bash

source ${VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh
echo "Deleting all VMs"
openstack server list |grep test* |awk '{print $2}' |xargs openstack server delete
