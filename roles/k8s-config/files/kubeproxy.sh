#!/bin/bash

print_help()
{
echo "Usage: $0 <start|stop>"
echo "    Example: $0 start"
echo "    Example: $0 stop"
}

if [ $# -ne 1 ]; then
    print_help
    exit 1
fi

status=$1

if [ "${status}" != "start" ] && [ "${status}" != "stop" ]; then
    print_help
    exit 1
fi

# check if the kubectl proxy is running
kpid=`ps -elf | grep "kubectl proxy" | grep -v grep | awk '{print $4}'`

if [ "${kpid}10" -ne "10" ];then
    echo "kubectl proxy stop running"
    kill -9 ${kpid}
fi

# export KUBECONFIG if not set
adminconf=/etc/kubernetes/admin.conf
if [ "${KUBECONFIG}x" == "x" ]; then
    export KUBECONFIG=${adminconf}
fi

# change the admin configuration file's owner
usr=`ls ${adminconf}  -la | awk -F ' ' '{print $3}'`
if [ "${usr}x" != ${USER} ]; then
    echo "Change the owner of ${adminconf} to be ${USER}"
    sudo -E chown ${USER}: ${adminconf}
fi

# start kubectl proxy in the background
if [ "${status}" == "start" ];then
    echo "kubectl proxy start running on port 8001 in background"
    nohup kubectl proxy --port 8001 1>/dev/null &
    sleep 5 # wait proxy for starting completely
fi
