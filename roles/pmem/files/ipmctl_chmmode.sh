#!/bin/bash

FULTYPE=${1}
SHRTYPE=${1:0:9} # cut the first 9 characters (size of "AppDirect")

# Export execute binary to a global env
WORKDIR=`dirname $0`
source ${WORKDIR}/ipmctl_setupvars.sh

# delete existing goal
${IPMCTLBIN} delete -goal

if [ "${SHRTYPE}" == "AppDirect" ]; then
    echo -e "+++++++++++++++++++Config Pmem In ${FULTYPE} Mode+++++++++++++++++++++++++++"
    echo y | ${IPMCTLBIN} create -goal PersistentMemoryType=${FULTYPE}
else
    echo -e "++++++++++++++++++Config Pmem In Memory Mode+++++++++++++++++++++++++++"
    echo y | ${IPMCTLBIN} create -goal MemoryMode=100
fi
echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
