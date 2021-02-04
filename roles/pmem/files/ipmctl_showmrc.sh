#!/bin/bash

# Export execute binary to a global env
WORKDIR=`dirname $0`
source ${WORKDIR}/ipmctl_setupvars.sh

# Test compiled binary
echo -e "\e[33m+++++++++++++++++++++++++++Show topology++++++++++++++++++++++++++++\e[0m"
${IPMCTLBIN} show -topology
echo -e "\e[33m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\e[0m"

echo -e "\e[33m++++++++++++++++++++++Show memory resources+++++++++++++++++++++++++\e[0m"
${IPMCTLBIN} show -memoryresources
echo -e "\e[33m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\e[0m"

echo -e "\e[33m+++++++++++++++++++++++++++Show dimm++++++++++++++++++++++++++++++++\e[0m"
${IPMCTLBIN} show -dimm
echo -e "\e[33m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\e[0m"
