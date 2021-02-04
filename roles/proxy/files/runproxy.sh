#!/bin/sh

temp=${LOCALTEMP}
SFILE=${temp}/script.tar.gz
SDIR=${temp}/script/
EPEL=${temp}/epel.repo

#install lsb-release
export http_proxy=http://child-prc.intel.com:913
export https_proxy=http://child-prc.intel.com:913
yum install -y redhat-lsb

#uncompress script.tar.gz
if [ ! -f "$SFILE" ]; then
    echo "$SFILE does not exist"
    exit 1
fi

tar xvzf $SFILE -C ${temp}

#nvigate to $SDIR
if [ ! -d "$SDIR" ]; then
    echo "$SDIR does not exist"
    exit 1
fi
cd $SDIR

#copy epel.repo to /etc/yum.repos.d/
if [ ! -f "$EPEL" ]; then
    echo "$EPEL does not exist"
    exit 1
fi
cp $EPEL /etc/yum.repos.d/


#setup environment
source ./environment.inc

#run redsocks.sh
./redsocks.sh

#restart redsocks
sudo systemctl restart redsocks

#run vm_setup.sh
./vm-setup.sh

#clean temporary files
cd  $(dirname $SDIR)

echo "###### Remove $SDIR ${SFILE##*/} ${EPEL##*/} in $(dirname $SDIR) ######"
rm  $SDIR -rf
rm  ${SFILE##*/} -f
rm  ${EPEL##*/} -f

