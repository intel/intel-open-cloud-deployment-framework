#!/bin/bash

# Activate environment
source ${OPS_VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

############################# Create glance image #########################
echo "Creating glance image"

# Check image path is valid
if [ ! -f $OPS_IMAGE_PATH ]; then
    echo "$OPS_IMAGE_PATH not found"
    exit 1
fi

# Check existing
existed=`openstack image list  | grep "$OPS_IMAGE_NAME" -w`
if [ "${existed}x" != "x" ]; then
    openstack image delete $OPS_IMAGE_NAME
fi
openstack image create --disk-format ${OPS_DISK_FORMAT} --container-format bare\
    --public --property os_type=${OPS_IMAGE_TYPE} --file ${OPS_IMAGE_PATH} \
    ${OPS_IMAGE_NAME}

IMG_LIST=`openstack image list`
# Return results format:
# +--------------------------------------+------------------------+--------+
# | ID                                   | Name                   | Status |
# +--------------------------------------+------------------------+--------+
# | 44fe37e3-9360-4d40-ad63-71bf1c7e11cc | Centos-7-x86_64_custom | active |
# +--------------------------------------+------------------------+--------+
# $1     $2                              $3      $4               $5  $6

IMG_HIT=$(echo "$IMG_LIST" | grep "$OPS_IMAGE_NAME" -w)
# Double ech to remove spaces
IMG_STA=$(echo $(echo "$IMG_HIT" | cut -d '|' -f 4)| tr "[A-Z]" "[a-z]")

if [ ! "$IMG_HIT" ] || [ "$IMG_STA" != "active" ]; then
   echo "openstack image created failed"
   exit 1
fi

##################### Create public/private network ########################
EX_NETWORK_NAME=${OPS_EX_NETWORK_NAME}
EX_SUBNET_NAME=${OPS_EX_SUBNET_NAME}
IN_NETWORK_NAME=${OPS_IN_NETWORK_NAME}
IN_SUBNET_NAME=${OPS_IN_SUBNET_NAME}

# This EXT_NET_CIDR is your public network,that you want to connect to internet
ENABLE_EXT_NET=${ENABLE_EXT_NET:-1}
EXT_NET_CIDR=${EXT_NET_CIDR:-'10.0.2.0/24'}
EXT_NET_RANGE=${EXT_NET_RANGE:-'start=10.0.2.2,end=10.0.2.254'}
EXT_NET_GATEWAY=${EXT_NET_GATEWAY:-'10.0.2.1'}
MAN_NET_RANGE=${MAN_NET_RANGE:-'start=10.0.10.2,end=10.0.10.254'}
MAN_NET_GATEWAY=${MAN_NET_GATEWAY:-'10.0.10.1'}
MAN_NET_CIDR=${MAN_NET_CIDR:-'10.0.10.0/24'}

ROUTER_FIX_IP='10.0.2.98'

# Prepare external network:
existed=`openstack network list  | grep "$EX_NETWORK_NAME" -w`
if [ "${existed}x" == "x" ]; then
    openstack network create --external --provider-physical-network physnet1 \
    --provider-network-type flat $EX_NETWORK_NAME
fi

# Fetch dns nameservers from localhost
dnss=$(cat /etc/resolv.conf | grep "nameserver" | while read line; \
    do dns_line=`echo "$line" | awk '{print $2}'`; echo -n "--dns-nameserver \
    $dns_line "; done)

# Create external subnet
existed=`openstack subnet list  | grep "$EX_SUBNET_NAME" -w`
if [ "${existed}x" == "x" ]; then
    openstack subnet create --subnet-range ${EXT_NET_CIDR} --gateway \
        ${EXT_NET_GATEWAY} --allocation-pool ${EXT_NET_RANGE} $dnss --network \
        ${EX_NETWORK_NAME} $EX_SUBNET_NAME
fi

# Create management network:
existed=`openstack network list  | grep "$IN_NETWORK_NAME" -w`
if [ "${existed}x" == "x" ]; then
    openstack network create --provider-network-type vxlan $IN_NETWORK_NAME
fi

# Create management subnet
existed=`openstack subnet list  | grep "$IN_SUBNET_NAME" -w`
if [ "${existed}x" == "x" ]; then
    openstack subnet create --subnet-range ${MAN_NET_CIDR} --gateway \
        ${MAN_NET_GATEWAY} --allocation-pool ${MAN_NET_RANGE} $dnss --network \
        $IN_NETWORK_NAME $IN_SUBNET_NAME
fi

# Create router:
ROUTER_NAME=demo-router

existed=`openstack network list  | grep "$ROUTER_NAME" -w`
if [ "${existed}x" == "x" ]; then
    openstack router create $ROUTER_NAME
    openstack router add subnet $ROUTER_NAME $IN_SUBNET_NAME
    openstack router set --enable-snat --external-gateway $EX_NETWORK_NAME \
        --fixed-ip subnet=$EX_SUBNET_NAME,ip-address=$ROUTER_FIX_IP $ROUTER_NAME
fi

ROUTER_LIST=`openstack router list`
# Return results format:
# +--------------------------------------+-------------+--------+-------+-------
# | ID                                   | Name        | Status | State | Projec
# +--------------------------------------+-------------+--------+-------+-------
# | d2f3e4c8-097b-4bab-82fa-d554359fe395 | demo-router | ACTIVE | UP    | 324778
# +--------------------------------------+-------------+--------+-------+-------

ROUTER_HIT=$(echo "$ROUTER_LIST" | grep "$ROUTER_NAME" -w)
# Double ech to remove spaces
ROUTER_STA=$(echo $(echo "$ROUTER_HIT" | cut -d '|' -f 4) | tr "[A-Z]" "[a-z]")

if [ ! "$ROUTER_HIT" ] || [ "$ROUTER_STA" != "active" ]; then
   echo "openstack router created failed"
   exit 1
fi

############################# Create flavor #########################

# Create PMEM flavors
PMEM_LABEL_ARRAY=()
PMEM_ENABALED=${OPS_VM_PMEM_ENABLED}
compute_conf=/etc/kolla/config/nova/nova-compute.conf
if [ "$PMEM_ENABALED" == "true" ] && [ -f "${compute_conf}" ]; then
    pmem_conf=`cat ${compute_conf} | grep "pmem_namespaces"`
    if [ "${pmem_conf}x" != "x" ]; then
        lines=`echo "$pmem_conf"  | awk -F '=' '{print $2 }' | \
            awk -F ',' '{ for (i=1; i<=NF; i++) print $i }'`
        for line in ${lines}
        do
            label=`echo $line | awk -F ':' '{print $1}'`
            PMEM_LABEL_ARRAY+=${label}
        done
    fi
fi

FLAVOR_ARRAY=(m1.tiny m1.small m1.medium m1.large m1.xlarge)
existed=`openstack flavor list`

ID_BASE=$OPS_ID_BASE
RAM_SIZE=$OPS_RAM_SIZE #M
DISK_SIZE=$OPS_DISK_SIZE #G
VCPUS_NUM=$OPS_VCPUS_NUM
MULTI_FACT=${OPS_MULTI_FACT}

INDEX=1
# Prepare common flavor:
# add default flavors, if they don't already exist
for flavor in ${FLAVOR_ARRAY[@]}
do
    # No any pmem namespaces
    if [ ${#PMEM_LABEL_ARRAY[@]} -eq 0 ]; then
        if ! echo "$existed" | grep -qw "$flavor"; then
            openstack flavor create --id $ID_BASE --ram $RAM_SIZE \
            --disk $DISK_SIZE --vcpus $VCPUS_NUM $flavor
        fi
    else
        for pmem_label in ${PMEM_LABEL_ARRAY[@]}
        do
            flavor_name=`echo ${flavor}.pmem_${pmem_label} | \
                tr '[:upper:]' '[:lower:]'`
            flavor_property="hw:pmem=$pmem_label"
            if ! echo "$existed" | grep -qw "${flavor_name}"; then
                openstack flavor create --id $ID_BASE --ram $RAM_SIZE \
                --disk $DISK_SIZE --vcpus $VCPUS_NUM --property \
                ${flavor_property} ${flavor_name}
            fi
        done
    fi
    ((INDEX++))
    ID_BASE=$INDEX
    RAM_SIZE=`expr $RAM_SIZE \* ${MULTI_FACT}`
    DISK_SIZE=`expr $DISK_SIZE \* ${MULTI_FACT}`
    VCPUS_NUM=`expr $VCPUS_NUM \* ${MULTI_FACT}`
done

############################# Create volume #########################
VOL_NUM=$OPS_VOLUME_NUM
VOL_SIZE=$OPS_VOLUME_SIZE #G
# Prepare volume with ceph backend
if [ "$OPS_CEPH_BACKEND_ENABLED" == "true" ]; then
    existed=`openstack volume type list`
    if ! echo "$existed" | grep ceph; then
        openstack volume type create ceph
    fi

    vol_name_prefix=ceph-vol
    vol_type=ceph
else
    vol_name_prefix=def-vol
    vol_type=__DEFAULT__
fi

if [ $vol_name_prefix ]; then
    existed=`openstack volume list`
    for index in $(seq 1 $VOL_NUM)
    do
        vol_name=${vol_name_prefix}-${index}
        vol_existed=`echo "$existed" | grep "$vol_name" -w`
        if [ "${vol_existed}x" != "x" ]; then
            openstack volume delete $vol_name
        fi

        # Comfirm and recreate
        vol_existed=`echo "$existed" | grep "$vol_name" -w`
        if [ "${vol_existed}x" == "x" ]; then
            openstack volume create --size $VOL_SIZE --type $vol_type $vol_name
        else
            echo "openstack volume delete $vol_name failed"
        fi
    done
fi

############################# Sec Group Config #########################
# Get admin user and tenant IDs
ADMIN_USER_ID=$(openstack user list | awk '/ admin / {print $2}')
ADMIN_PROJECT_ID=$(openstack project list | awk '/ admin / {print $2}')
ADMIN_SEC_GROUP=$(openstack security group list --project ${ADMIN_PROJECT_ID} \
  | awk '/ default / {print $2}')

# Sec Group Config
if [ "$SG_RULE_ALL_PORT" == "true" ]; then
    openstack security group rule create --ingress --ethertype IPv4  \
        --protocol tcp --dst-port 1:65535 ${ADMIN_SEC_GROUP}
    openstack security group rule create --egress --ethertype IPv4  \
        --protocol tcp --dst-port 1:65535 ${ADMIN_SEC_GROUP}
else
    openstack security group rule create --ingress --ethertype IPv4 --protocol \
        icmp ${ADMIN_SEC_GROUP}

    DST_PORT_ARRAY=(22 8000 8080)
    for port in ${DST_PORT_ARRAY[@]}
    do
        openstack security group rule create --ingress --ethertype IPv4 \
            --protocol tcp --dst-port $port ${ADMIN_SEC_GROUP}
    done
fi

############################# Create  Key #########################
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo Generating ssh key.
    ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
fi

if [ -r ~/.ssh/id_rsa.pub ]; then
    echo Configuring nova public key and quotas.
    openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
fi

############################# Resource Quotas Config #########################
INST_NUM=$OPS_QUOTA_INST_NUM
CORE_NUM=$OPS_QUOTA_CORE_NUM
RAM_SIZE=$OPS_QUOTA_RAM_SIZE #Mbytes
# Increase the quota to allow 40 m1.small instances to be created
# INST_NUM instance
openstack quota set --instances $INST_NUM ${ADMIN_PROJECT_ID}

# CORE_NUM cores
openstack quota set --cores $CORE_NUM ${ADMIN_PROJECT_ID}

# RAM_SIZE ram
openstack quota set --ram $RAM_SIZE ${ADMIN_PROJECT_ID}

echo prepare openstack resource successfully

# Show created resources
echo "Show created resources"

rc_array=(image network subnet router volume flavor key)
for item in ${rc_array[@]}
do
    echo
    echo "openstack ${item} list"
    existed=`openstack ${item} list`
    if [ "${existed}x" == "x" ]; then
        echo "Empty"
    else
        echo "$existed"
    fi
    echo
done
