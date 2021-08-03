#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <host ip address>[host ip address]"
    echo "    Example: $0 172.18.0.2 172.18.0.3"
    exit 1
fi

for node_ip in "$@"; do
    node=`kubectl get nodes -o wide | grep ${node_ip} | awk '{print $1}'`
    kubectl label node $node benchmark=memtier
done
