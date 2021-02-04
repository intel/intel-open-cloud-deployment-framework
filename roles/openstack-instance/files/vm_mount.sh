#!/bin/bash

source ${OPS_VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

timeout=${OPS_MOUNT_TIMEOUT}
mnt_dev=${OPS_MOUNT_DEVICE}

servers=`openstack server list`

for index in $(seq ${OPS_VM_NUM} -1 1); do
    # Concentrate server's name
    server=${OPS_VM_NAME}-${index}
    mounted=false
    # If server is not found, turn to next
    existed=`echo "$servers" | grep "$server" -iw`
    if [ "${existed}x" == "x" ]; then
        echo "$server not found, skipped"
        continue
    fi

    # Loop existing volumes
    volumes=`openstack volume list | awk 'NR>3' | grep '|'`
    while IFS='' read -r line
    do
        status=`echo $(echo "$line" | awk -F '|' '{print $4}')`
        if [ "${status}x" == "availablex" ]; then
            id=`echo $(echo $line | awk -F '|' '{print $2}')`
            name=`echo $(echo $line | awk -F '|' '{print $3}')`

            # Attach volume to server
            openstack server add volume --device ${mnt_dev} ${server} \
                ${name}

            # Not check attaching status if timeout is equal to or lower than 0
            if [ ${timeout} -le 0 ]; then
                continue
            fi

            # Wait ${timeout} * ${timeout} seconds for attaching each volume
            max_wait=${timeout}
            for time in $(seq 1 $max_wait)
            do
                volmnt=`openstack volume list | grep "$id"`
                status=`echo $(echo "$volmnt" | awk -F '|' '{print $4}')`

                if [ "${status}x" != "in-usex" ] && [ ${time} -eq ${max_wait} ]; then
                    echo "volume $name is attached to ${server} failed"
                elif [ "${status}x" == "in-usex" ]; then
                    echo "volume $name is attached to ${server} successfully"
                    mounted=true
                    break
                fi
                sleep ${timeout} # wait timeout seconds for attaching
            done
            if [ "$mounted" == true ]; then
                break
            fi
        elif [ "${status}x" == "in-usex" ]; then
            echo "volume with name: $name and id: $id is in-use status, skipped"
        else
            echo "volume with name: $name and id: $id is in abnormal status, skipped"
        fi
    done < <(echo "$volumes")
done
