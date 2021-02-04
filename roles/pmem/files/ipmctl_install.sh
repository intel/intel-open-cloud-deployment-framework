#!/bin/bash

# save current path
CURRENT=${PWD}

# build directory
BUILD=output

# build artifacts can be found in output/release
mkdir ${BUILD} && cd ${BUILD}

# find cmake installed
ret=$(command -v cmake)
if [ ! $ret ]; then
    echo "cmake not found"
    exit 1
fi

cmake -DRELEASE=ON -DCMAKE_INSTALL_PREFIX=/ .. > /dev/null 2>&1

# find make installed
ret=$(command -v make)
if [ ! $ret ]; then
    echo "make not found"
    exit 1
fi
make -j all > /dev/null 2>&1

# Instal as the appropriate case
#make install

# Export execute binary to a global env
IPMCTLBIN=${CURRENT}/${BUILD}/release/ipmctl
IPMCTLLIB=${CURRENT}/${BUILD}/release/
sed -i "s|###IPMCTLBIN###|${IPMCTLBIN}|g" ${CURRENT}/ipmctl_setupvars.sh
sed -i "s|###IPMCTLLIB###|${IPMCTLLIB}|g" ${CURRENT}/ipmctl_setupvars.sh
echo "$IPMCTLBIN"
