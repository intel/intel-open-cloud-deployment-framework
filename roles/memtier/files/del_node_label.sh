#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <host ip address>[host ip address]"
    echo "    Example: $0 172.18.0.2 172.18.0.3"
    exit 1
fi

for node_ip in "$@"; do
    # get hostname from /etc/hosts
    node=`grep -r ${node_ip} /etc/hosts | awk '{ print $3 }'`
    kubectl label node $node benchmark-
done
