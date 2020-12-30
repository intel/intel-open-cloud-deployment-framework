#!/bin/bash

ARCH=$(uname -m)

# Create glance iamge:
echo Creating glance image
source ${VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

# Check existing 
existed=`openstack image list  | grep "$IMAGE_NAME"`
if [ "${existed}x" != "x" ]; then
    openstack image delete $IMAGE_NAME
fi
openstack image create --disk-format qcow2 --container-format bare --public \
--property os_type=${IMAGE_TYPE} --file ${IMAGE_PATH} ${IMAGE_NAME}

# This EXT_NET_CIDR is your public network,that you want to connect to the internet via
ENABLE_EXT_NET=${ENABLE_EXT_NET:-1}
EXT_NET_CIDR=${EXT_NET_CIDR:-'10.0.2.0/24'}
EXT_NET_RANGE=${EXT_NET_RANGE:-'start=10.0.2.99,end=10.0.2.149'}
EXT_NET_GATEWAY=${EXT_NET_GATEWAY:-'10.0.2.1'}
MAN_NET_RANGE=${MAN_NET_RANGE:-'start=10.0.10.99,end=10.0.10.149'}
MAN_NET_GATEWAY=${MAN_NET_GATEWAY:-'10.0.10.1'}
MAN_NET_CIDR=${MAN_NET_CIDR:-'10.0.10.0/24'}

EX_NETWORK_NAME="public1"
EX_SUBNET_NAME="public1_subnet"
IN_NETWORK_NAME="demo_net"
IN_SUBNET_NAME="demo_subnet"

# Prepare network:
existed=`openstack network list  | grep "$EX_NETWORK_NAME"`
if [ "${existed}x" == "x" ]; then
    openstack network create --external --provider-physical-network physnet1 --provider-network-type flat $EX_NETWORK_NAME
fi

# Create external subnet
existed=`openstack subnet list  | grep "$EX_SUBNET_NAME"`
if [ "${existed}x" == "x" ]; then
    openstack subnet create --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} \
	--allocation-pool ${EXT_NET_RANGE} $(cat /etc/resolv.conf | grep "nameserver" | while read line; do dns_line=`echo "$line" | awk '{print $2}'`; echo -n "--dns-nameserver $dns_line "; done) --network ${EX_NETWORK_NAME} $EX_SUBNET_NAME
fi

# Create management network:
existed=`openstack network list  | grep "$IN_NETWORK_NAME"`
if [ "${existed}x" == "x" ]; then
    openstack network create --provider-network-type vxlan $IN_NETWORK_NAME
fi

# Create management subnet
existed=`openstack subnet list  | grep "$IN_SUBNET_NAME"`
if [ "${existed}x" == "x" ]; then
    openstack subnet create --subnet-range ${MAN_NET_CIDR} --gateway ${MAN_NET_GATEWAY} \
	--allocation-pool ${MAN_NET_RANGE} $(cat /etc/resolv.conf | grep "nameserver" | while read line; do dns_line=`echo "$line" | awk '{print $2}'`; echo -n "--dns-nameserver $dns_line "; done) --network $IN_NETWORK_NAME $IN_SUBNET_NAME
fi

# Create router:

ROUTER_NAME=demo-router

existed=`openstack network list  | grep "$ROUTER_NAME"`
if [ "${existed}x" == "x" ]; then
    openstack router create $ROUTER_NAME
    openstack router add subnet $ROUTER_NAME $IN_SUBNET_NAME
    openstack router set --enable-snat --external-gateway $EX_NETWORK_NAME --fixed-ip subnet=$EX_SUBNET_NAME,ip-address=10.0.2.98 $ROUTER_NAME
fi

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
# 40 instance
openstack quota set --instances 40 ${ADMIN_PROJECT_ID}

# 40 cores
openstack quota set --cores 40 ${ADMIN_PROJECT_ID}

# 96GB ram
openstack quota set --ram 96000 ${ADMIN_PROJECT_ID}

echo prepare openstack resource successfully
