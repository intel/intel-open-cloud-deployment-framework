#!/bin/bash

source ${OPS_VIRTUAL_PATH}/bin/activate
cd ${KOLLA_ANSIBLE_PATH}/tools

./kolla-ansible post-deploy

openrc=/etc/kolla/admin-openrc.sh 
if [ "${openrc}x" == "x" ]; then
    echo "kolla-anible post-deploy failed"
fi
