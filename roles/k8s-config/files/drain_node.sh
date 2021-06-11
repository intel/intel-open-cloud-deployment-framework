#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <hostname|ip address>[hostname|ip address]"
    echo "    Example: $0 node1 node2 node3"
    echo "    Example: $0 172.18.0.2 172.18.0.3"
    exit 1
fi

logfile=${LOCALTEMP}/drain_node.log

# export KUBECONFIG if not set
adminconf=/etc/kubernetes/admin.conf
if [ "${KUBECONFIG}x" == "x" ]; then
    export KUBECONFIG=${adminconf}
fi

# change the admin configration file's owner
usr=`ls ${adminconf}  -la | awk -F ' ' '{print $3}'`
if [ "${usr}x" != ${USER} ]; then
    echo "Change the owner of ${adminconf} to be ${USER}"
    sudo -E chown ${USER}: ${adminconf}
fi

for node in "$@"; do
    echo "drain and restart kubelet node: $node"
    kubectl drain ${node} --ignore-daemonsets > ${logfile} 2>& 1 # perform on master
    
    err=`cat ${logfile} | grep -i "error"`
    tip=`cat ${logfile} | grep -i "[--]delete[-]local[-]data"`
    if [ "${err}x" != "x" ] && [ "${tip}x" != "x" ];then
        echo "Try to drain ${node} with --delete-local-data option!"
        kubectl drain ${node} --ignore-daemonsets --delete-local-data > ${logfile} 2>& 1
    fi
    
    err=`cat ${logfile} | grep -i "error"`
    if [ "${err}x" != "x" ];then
        echo "kubectl drain ${node} failed, you may find the cause in ${logfile}"
        exit 1  
    fi

    # Get node ip from /etc/hosts
    node_ip=`grep -r ${node} /etc/hosts | awk '{ print $1 }'`
    echo "ssh START" >> ${logfile}
    echo $node_ip >> ${logfile}
    ssh ${node_ip} sudo -E rm -rf /var/lib/kubelet/cpu_manager_state # perform on node
    ssh ${node_ip} sudo -E systemctl restart kubelet # perform on node
    echo "ssh END" >> ${logfile}
    kubectl uncordon ${node} # perform on master
done
