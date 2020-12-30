#!/bin/bash

ARCH=$(uname -m)
IMAGE_PATH=/home/centos
IMAGE=centos.qcow2
IMAGE_NAME=centos
IMAGE_TYPE=linux

# Create glance iamge:
echo Creating glance image.
openstack image create --disk-format qcow2 --container-format bare --public \
    --property os_type=${IMAGE_TYPE} --file ${IMAGE_PATH}/${IMAGE} ${IMAGE_NAME}

# This EXT_NET_CIDR is your public network,that you want to connect to the internet via.
ENABLE_EXT_NET=${ENABLE_EXT_NET:-1}
EXT_NET_CIDR=${EXT_NET_CIDR:-'10.0.2.0/24'}
EXT_NET_RANGE=${EXT_NET_RANGE:-'start=10.0.2.99,end=10.0.2.149'}
EXT_NET_GATEWAY=${EXT_NET_GATEWAY:-'10.0.2.1'}
DNS_NAMESERVER1=${DNS_NAMESERVER1:-'10.248.2.5'}
DNS_NAMESERVER2=${DNS_NAMESERVER2:-'10.239.27.228'}
DNS_NAMESERVER3=${DNS_NAMESERVER3:-'172.17.6.9'}

    openstack subnet create --no-dhcp \
        --allocation-pool ${EXT_NET_RANGE} --network public1 \
        --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} public1-subnet

# Prepare network:
echo Configuring neutron
# Create external network:
openstack network create --external --provider-physical-network physnet1 --provider-network-type flat public1
openstack subnet create --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} --allocation-pool EXT_NET_RANGE --dns-nameserver DNS_NAMESERVER1 --dns-nameserver DNS_NAMESERVER2 --dns-nameserver DNS_NAMESERVE3 --network public1 public1-subnet

# Create management network:
openstack network create --provider-network-type vxlan demo-net
openstack subnet create --subnet-range 10.0.10.0/24 --gateway 10.0.10.1 --allocation-pool start=10.0.10.99,end=10.0.10.149 --dns-nameserver 10.248.2.5 --dns-nameserver 10.239.27.228 --dns-nameserver 172.17.6.9 --network demo-net demo-subnet


# Create router:
openstack router create demo-router
openstack router add subnet demo-router demo-subnet
openstack router set --enable-snat --external-gateway public1 --fixed-ip subnet=public1-subnet,ip-address=10.0.2.98 demo-router



# Prepare common flavor:
# add default flavors, if they don't already exist
if ! openstack flavor list | grep -q m1.tiny; then
    openstack flavor create --id 1 --ram 512 --disk 1 --vcpus 1 m1.tiny
    openstack flavor create --id 2 --ram 2048 --disk 20 --vcpus 1 m1.small
    openstack flavor create --id 3 --ram 4096 --disk 40 --vcpus 2 m1.medium
    openstack flavor create --id 4 --ram 8192 --disk 80 --vcpus 4 m1.large
    openstack flavor create --id 5 --ram 16384 --disk 160 --vcpus 8 m1.xlarge
fi


# Prepare volume with ceph backend:



# Get admin user and tenant IDs
ADMIN_USER_ID=$(openstack user list | awk '/ admin / {print $2}')
ADMIN_PROJECT_ID=$(openstack project list | awk '/ admin / {print $2}')
ADMIN_SEC_GROUP=$(openstack security group list --project ${ADMIN_PROJECT_ID} | awk '/ default / {print $2}')

# Sec Group Config
openstack security group rule create --ingress --ethertype IPv4 --protocol icmp ${ADMIN_SEC_GROUP}
openstack security group rule create --ingress --ethertype IPv4 --protocol tcp --dst-port 22 ${ADMIN_SEC_GROUP}
# Open heat-cfn so it can run on a different host
openstack security group rule create --ingress --ethertype IPv4 --protocol tcp --dst-port 8000 ${ADMIN_SEC_GROUP}
openstack security group rule create --ingress --ethertype IPv4 --protocol tcp --dst-port 8080 ${ADMIN_SEC_GROUP}


if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo Generating ssh key.
    ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
fi
if [ -r ~/.ssh/id_rsa.pub ]; then
    echo Configuring nova public key and quotas.
    openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
fi

# Increase the quota to allow 40 m1.small instances to be created
# 40 instances
openstack quota set --instances 40 ${ADMIN_PROJECT_ID}

# 40 cores
openstack quota set --cores 40 ${ADMIN_PROJECT_ID}

# 96GB ram
openstack quota set --ram 96000 ${ADMIN_PROJECT_ID}
