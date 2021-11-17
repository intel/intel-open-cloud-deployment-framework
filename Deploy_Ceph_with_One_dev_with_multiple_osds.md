# Deploy Ceph with one device with multiple osds

## Prerequisites
- Install CentOS-7 OS on all nodes

## Steps 
1. Prepare logical group and logical volumes

    Here we use logical volume to suport 1 device : multiple osds.

    You can follow "How to generate logical group and logical volumes via lvm.yaml?" to generate logical group and logical volumes or you can generate them by yoursefl.

2. Environment setup before running the scripts on all nodes

    - We should better sync time zone on all nodes(If timezone is unified when installing OS, please omit this step), use command such as:

	    `$ timedatectl set-timezone Asia/Shanghai`
    - Sync time on all nodes, it is necessary, use command:
	
	    `$ ntpdate <ntp_server>`
    - If ntpdate is not installed, we can install it via command:
	
	    `$ yum install ntpdate -y` 

3. Create a common user with the same password for ansible on each node.
    
    For example:

        sudo useradd -m centos
        sudo passwd cento

4. As root user to add current user to /etc/sudoers on all nodes, add the following line into the bottom of /etc/sudoers on all nodes.

        sudo vim /etc/sudoers
            # Allow members of group sudo to execute any command
            %sudo   ALL=(ALL:ALL) ALL
            centos  ALL=(ALL)     NOPASSWD: ALL  ## add this line

5. Prepare OpenCloud on deployment node (CentOS7)

    5.1 Install tools

        sudo yum install git -y
        sudo yum install epel-release.noarch -y
        sudo yum install ansible -y
        sudo yum install python36 -y

    5.2 Clone OpenCloud repository

        git clone https://gitlab.devtools.intel.com/essprc/opencloud2.0.git

    5.3 Edit **inventory/hosts** to add IPs of all hosts for ssh.

        [all_hosts]
	    10.1.1.1  # Deployment node, the deployment node can be one of ceph nodes.
	    10.1.1.2  # Ceph node
	    10.1.1.3  # Ceph node
	    10.1.1.4  # Ceph node

        [ssh_hosts:children]
        all_hosts

    5.4 Config ssh (If we switch to new hosts, new config for hosts, we need to remove known_host file firstly)

        export ANSIBLE_HOST_KEY_CHECKING=False
        ansible-playbook -e ansible_ssh_user="centos" -e ansible_ssh_pass=<user_password> -i inventory/hosts ssh.yaml
        Note: use the user created in step1.
    
    5.5 Edit **inventory/hosts** for Ceph

        [deployment_host]
        localhost

        [ceph_hosts]
	    10.1.1.2  # Ceph node
	    10.1.1.3  # Ceph node
	    10.1.1.4  # Ceph node

        [ceph_openstack:children]
        deployment_host

    5.6 Edit **group_vars/all** for Ceph

    For exmaple:

        glocalcache: /xxx
        glocaltemp: /tmp
        ops_external_ceph: true # use your own Ceph.
        ceph_network_ifg: eno1 # set it based on your network
        # Set it to true if you want to use logical volumes
        ceph_use_lvm: true
        ceph_lvm_volumes: 
          - data: datalv1   ## set it with logical volume
            data_vg: sdbvg  ## set it with volume group
          - data: datalv2
            data_vg: sdbvg
          - data: datalv3
            data_vg: sdbvg
          - data: datalv4
            data_vg: sdbvg
          - data: datalv1
            data_vg: sdcvg
          - data: datalv2
            data_vg: sdcvg
          - data: datalv3
            data_vg: sdcvg
          - data: datalv4
            data_vg: sdcvg

    5.7 Run Ceph ansible script

    For k8s:

        ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts ceph-k8s.yaml

        # if you only want to deploy Ceph, ceph-k8s is also ok for you.
    
    For OpenStack:

        ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts ceph-openstack.yaml

## How to generate logical group and logical volumes via lvm.yaml?

1. Edit **inventory/hosts**.

        [ceph_hosts]
        10.0.1.1
        10.0.1.2
        10.0.1.3

2. Edit **group_vars/all**.

    For exmaple:

        ceph_block_devices:
          - /dev/sdb  ## set it based on your hardware resources
          - /dev/sdc
          ...

        # Logical volume size
        lvm_lv_size: 100G # set it based on your requirement.

        # Set logical volume quantity for each device, such as device /dev/sdb
        # 1 device : <lvm_lvs_per_dev> osds
        lvm_lvs_per_dev: 4 ## needs to >=1, set it based on your requirement. 

3. Run lvm ansible script

        ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts lvm.yaml

