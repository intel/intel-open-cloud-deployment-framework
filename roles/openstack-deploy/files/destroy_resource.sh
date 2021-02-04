#!/bin/bash
OPS_VIRTUAL_PATH=/home/centos/intel/openstackvenv/
# Activate environment
source ${OPS_VIRTUAL_PATH}/bin/activate
source /etc/kolla/admin-openrc.sh

# Delete flavors
# +-----+-----------+--------+------+-----------+-------+-----------+
# | ID  | Name      |    RAM | Disk | Ephemeral | VCPUs | Is Public |
# +-----+-----------+--------+------+-----------+-------+-----------+
# | 1   | m1.tiny   |   2048 |   10 |         0 |     1 | True      |
# | 2   | m1.xlarge | 245760 | 1200 |         0 |   120 | True      |
# | 3   | m1.small  |   4096 |   20 |         0 |     2 | True      |
# | 4   | m1.large  |  49152 |  240 |         0 |    24 | True      |
# | 5   | m1.medium |  12288 |   60 |         0 |     6 | True      |
# +-----+-----------+--------+------+-----------+-------+-----------+

existed=`openstack flavor list`
if [ "${existed}x" != "x" ]; then
    echo "$existed"| grep "m1" | cut -d '|' -f 3 | while read line
    do
        echo "openstack flavor delete $line"
        openstack flavor delete $line
    done
fi

# Delete ssh key
# +--------+-------------------------------------------------+
# | Name   | Fingerprint                                     |
# +--------+-------------------------------------------------+
# | mykey  | 3d:90:37:94:ba:e7:a7:89:80:fb:ad:91:23:cb:83:f3 |
# | mykey2 | 3d:90:37:94:ba:e7:a7:89:80:fb:ad:91:23:cb:83:f3 |
# +--------+-------------------------------------------------+

existed=`openstack key list`
if [ "${existed}x" != "x" ]; then
    echo "$existed" | awk 'NR>3'| grep "|" | cut -d '|' -f 2 | while read line
    do
        echo "openstack key delete $line"
        openstack key delete $line
    done
fi

# Delete volume
# +--------------------------------------+-------+-----------+------+-------------+
# | ID                                   | Name  | Status    | Size | Attached to |
# +--------------------------------------+-------+-----------+------+-------------+
# | accfa20d-e01d-42b8-8476-14113517857a | vol-3 | available |   20 |             |
# | 8d724522-792e-4ae3-9020-b012324a64fe | vol-2 | available |   20 |             |
# | cbb7912f-2d6b-431b-9570-65433db8ab2a | vol-1 | available |   20 |             |
# | fae8c936-d3e1-4ec4-9082-c7daa3fda2da | vol-3 | available |   20 |             |
# | 93e20ded-1fc8-4a5f-b84b-d149aaaa8ab5 | vol-2 | available |   20 |             |
# | ab15f2b6-70b1-4c46-8bb3-18e6afb94abf | vol-1 | available |   20 |             |
# +--------------------------------------+-------+-----------+------+-------------+

existed=`openstack volume list`
if [ "${existed}x" != "x" ]; then
    echo "$existed" | awk 'NR>3'| grep "|" | cut -d '|' -f 2 | while read line
    do
        echo "openstack volume delete $line"
        openstack volume delete $line
    done
fi

# Delete router
# +--------------------------------------+-------------+--------+-------+----------------------------------+-------------+-------+
# | ID                                   | Name        | Status | State | Project                          | Distributed | HA    |
# +--------------------------------------+-------------+--------+-------+----------------------------------+-------------+-------+
# | 963c1580-d6c0-46b5-a04a-f4b662386e4f | demo-router | ACTIVE | UP    | 301d66d0ab954f79a83497a13bc85c4e | False       | False |
# +--------------------------------------+-------------+--------+-------+----------------------------------+-------------+-------+

existed=`openstack router list`

# Delete subnet
# +--------------------------------------+----------------+--------------------------------------+--------------+
# | ID                                   | Name           | Network                              | Subnet       |
# +--------------------------------------+----------------+--------------------------------------+--------------+
# | 44fcb69d-cd35-460b-ae4e-73a98385f574 | public1_subnet | 8e8b0173-f04c-47d9-b87f-1c599907e9c1 | 10.0.2.0/24  |
# | 9320d4cd-ec00-44df-850e-f2b4ed5ac250 | private_subnet | 61ec6976-41c4-4fa7-8931-6c9351730cee | 10.0.10.0/24 |
# +--------------------------------------+----------------+--------------------------------------+--------------+

subnets=`openstack subnet list`

# Delete port
# +--------------------------------------+------+-------------------+--------------------------------------------------------------------------+--------+
# | ID                                   | Name | MAC Address       | Fixed IP Addresses                                                       | Status |
# +--------------------------------------+------+-------------------+--------------------------------------------------------------------------+--------+
# | 7a24be91-f2a2-4ac2-a862-9f72099b5aef |      | fa:16:3e:ef:7c:6f | ip_address='10.0.2.98', subnet_id='44fcb69d-cd35-460b-ae4e-73a98385f574' | ACTIVE |
# | d7b2b238-e0b8-4020-b3cd-39b1e82684f5 |      | fa:16:3e:a5:06:01 | ip_address='10.0.10.2', subnet_id='9320d4cd-ec00-44df-850e-f2b4ed5ac250' | ACTIVE |
# | d8680d37-09c3-4f31-8661-86f548b4265a |      | fa:16:3e:1a:40:3a | ip_address='10.0.2.2', subnet_id='44fcb69d-cd35-460b-ae4e-73a98385f574'  | ACTIVE |
# | e5aa81c3-b94c-46c9-b42e-760c318c7428 |      | fa:16:3e:23:65:84 | ip_address='10.0.10.1', subnet_id='9320d4cd-ec00-44df-850e-f2b4ed5ac250' | ACTIVE |
# +--------------------------------------+------+-------------------+--------------------------------------------------------------------------+--------+

if [ "${existed}x" != "x" ] || [ "${subnets}x" != "x" ] || \
    [ "${ports}x" != "x" ]; then
    routerid=`echo "$existed" | awk 'NR>3'| grep "|" | cut -d '|' -f 2`
    subnetid=`echo "$subnets" | awk 'NR>3'| grep "|" | cut -d '|' -f 2`

    # Remove subnets from routers
    if [ "${routerid}x" != "x" ] && [ "${subnetid}x" != "x" ];then 
        echo "$routerid" | while read rid
        do
            echo "$subnetid" | while read sid
            do
                echo "Remove subnet $sid from $rid"
                openstack router remove subnet $rid $sid > /dev/null 2>&1
            done
        done
    fi

    if [ "${subnetid}x" != "x" ];then 
        # Delete subnets
        echo "$subnetid" | while read sid
        do
            echo "Delete subnet $sid"
            openstack subnet delete $sid > /dev/null 2>&1
        done
    fi

    if [ "${routerid}x" != "x" ] ;then 
        # Delete router
        echo "$routerid" | while read rid
        do
            echo "Delete router $rid"
            openstack router delete $rid  > /dev/null 2>&1
        done
    fi

    ports=`openstack port list`
    portid=`echo "$ports" | awk 'NR>3'| grep "|" | cut -d '|' -f 2`

    if [ "${portid}x" != "x" ] ;then 
        # Delete port
        echo "$portid" | while read pid
        do
            echo "Delete router $pid"
            openstack port delete $pid  > /dev/null 2>&1
        done
    fi
fi

# Delete network
# +--------------------------------------+-------------+---------+
# | ID                                   | Name        | Subnets |
# +--------------------------------------+-------------+---------+
# | 61ec6976-41c4-4fa7-8931-6c9351730cee | private_net |         |
# | 8e8b0173-f04c-47d9-b87f-1c599907e9c1 | public_net  |         |
# +--------------------------------------+-------------+---------+

existed=`openstack network list`
if [ "${existed}x" != "x" ]; then
    echo "$existed" | awk 'NR>3'| grep "|" | cut -d '|' -f 2 | while read line
    do
        echo "openstack network delete $line"
        openstack network delete $line
    done
fi

# Delete images
# +--------------------------------------+--------+--------+
# | ID                                   | Name   | Status |
# +--------------------------------------+--------+--------+
# | 8589c836-f6b4-45f5-820f-1113724b11cf | Centos | active |
# +--------------------------------------+--------+--------+

existed=`openstack image list`
if [ "${existed}x" != "x" ]; then
    echo "$existed" | awk 'NR>3'| grep "|" | cut -d '|' -f 2 | while read line
    do
        echo "openstack image delete $line"
        openstack image delete $line
    done
fi

# +--------------------------------------+-------------+-----------+-----------+------------+--------------------------------------+--------------------------------------+
# | ID                                   | IP Protocol | Ethertype | IP Range  | Port Range | Remote Security Group                | Security Group                       |
# +--------------------------------------+-------------+-----------+-----------+------------+--------------------------------------+--------------------------------------+
# | 07775010-af5b-4b17-8a01-2d8acc0eef57 | None        | IPv6      | ::/0      |            | a2dbac75-f0bb-4889-9e02-480652bdce32 | a2dbac75-f0bb-4889-9e02-480652bdce32 |
# | 21870d3b-debd-436d-bd4c-f48146bf8319 | None        | IPv4      | 0.0.0.0/0 |            | a2dbac75-f0bb-4889-9e02-480652bdce32 | a2dbac75-f0bb-4889-9e02-480652bdce32 |
# | 22fea083-418f-4c0d-ace9-d902aba6d8a8 | None        | IPv6      | ::/0      |            | 4700fc68-6f2e-4257-9185-946b1e5c3e71 | 4700fc68-6f2e-4257-9185-946b1e5c3e71 |
# | 4b984efb-8f1a-441a-86f8-c62e9a40ae59 | None        | IPv4      | 0.0.0.0/0 |            | None                                 | a2dbac75-f0bb-4889-9e02-480652bdce32 |
# | 5c5fc232-cfc1-4e48-b86a-8f1d1a2bc326 | None        | IPv4      | 0.0.0.0/0 |            | 4700fc68-6f2e-4257-9185-946b1e5c3e71 | 4700fc68-6f2e-4257-9185-946b1e5c3e71 |
# | ae1ac510-fa2a-416a-a6d1-c82b75106bd6 | None        | IPv4      | 0.0.0.0/0 |            | None                                 | 4700fc68-6f2e-4257-9185-946b1e5c3e71 |
# | aed26ffd-9ded-484b-9d3e-8a8e6e5237cb | icmp        | IPv4      | 0.0.0.0/0 |            | None                                 | a2dbac75-f0bb-4889-9e02-480652bdce32 |
# | bae25c35-a110-420f-8338-771f0553a3ec | None        | IPv6      | ::/0      |            | None                                 | 4700fc68-6f2e-4257-9185-946b1e5c3e71 |
# | c1472f86-c5d4-4bad-af60-e490f2a0647a | None        | IPv6      | ::/0      |            | None                                 | a2dbac75-f0bb-4889-9e02-480652bdce32 |
# | d3ae5702-c111-46e8-b4d5-54f5faecb9c5 | tcp         | IPv4      | 0.0.0.0/0 | 8080:8080  | None                                 | a2dbac75-f0bb-4889-9e02-480652bdce32 |
# | d930eb01-cff1-4808-b10a-e39b9f913bf9 | tcp         | IPv4      | 0.0.0.0/0 | 22:22      | None                                 | a2dbac75-f0bb-4889-9e02-480652bdce32 |
# | e51cf15a-d137-4bae-980e-e257a71c68b2 | tcp         | IPv4      | 0.0.0.0/0 | 8000:8000  | None                                 | a2dbac75-f0bb-4889-9e02-480652bdce32 |
# +--------------------------------------+-------------+-----------+-----------+------------+--------------------------------------+--------------------------------------+

existed=`openstack security group rule list`
if [ "${existed}x" != "x" ]; then
    echo "$existed" | awk 'NR>3'| grep "|" | cut -d '|' -f 2 | while read line
    do
        echo "openstack security group rule delete $line"
        openstack security group rule delete $line
    done
fi

# Show remaining resources
echo "Show remaining resources"

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
