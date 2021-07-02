#!/bin/bash

# show nodes label
echo "show nodes label:"
echo "`kubectl get nodes -o wide --show-labels`"
echo

# show running pods
echo "show running pods:"
echo "`kubectl get po -o wide --all-namespaces`"
echo

# show storage class
echo "show storage class:"
echo "`kubectl get sc`"
echo
