# !/bin/bash

# Activate environment
source ${OPS_VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

rc_array=(image network subnet router volume flavor key)
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
