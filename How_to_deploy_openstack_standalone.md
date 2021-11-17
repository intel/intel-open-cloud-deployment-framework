# How to only deploy OpenStack Standalone

## Prerequisites
- Install CentOS-7 OS on all nodes

## Steps 
1. Prepare cinder-volumes Volume Group on Compute node
    

        lsblk # find devices you want to use, i.e. /dev/sdb 
        pvcreate /dev/sdb # create physical volume with lvm
        vgcreate cinder-volumes /dev/sdb # create the cinder-volumes volume group
        vgscan # check volume group

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
	    10.1.1.1  # Deployment node, the deployment node and OpenStack controller node can be the same node
	    10.1.1.2  # OpenStack controller node
	    10.1.1.3  # OpenStack compute node
	    10.1.1.4  # OpenStack compute node

        [ssh_hosts:children]
        all_host

    5.4 Config ssh (If we switch to new hosts, new config for hosts, we need to remove known_host file firstly)

        export ANSIBLE_HOST_KEY_CHECKING=False
        ansible-playbook -e ansible_ssh_user="centos" -e ansible_ssh_pass=<user_password> -i inventory/hosts ssh.yaml
        Note: use the user created in step1.
    
    5.5 Edit **inventory/hosts** for OpenStack

        [controller_hosts]
	    10.1.1.2  # OpenStack controller node

        [compute_hosts]
	    10.1.1.3  # OpenStack compute node
	    10.1.1.4  # OpenStack compute node

        [deployment_host]
        localhost

        [neutron_hosts:children]
        controller_hosts

    5.6 Edit **group_vars/all** for OpenStack

        glocalcache: /xxx
        glocaltemp: /tmp
        ops_external_ceph: false # Not use your own Ceph.
        ops_local_registry: true
        ops_docker_registry: 10.67.125.31:4000
        ops_kolla_internal_vip_address: 10.67.125.94
        ops_network_interface: eno1
        ops_network_external_interface: tap0
        ops_keepalived_virtual_router_id: "176"
        ops_storage_interface: eno1
        glance_image_path: "/home/centos/workspace/centos7.qcow2"

    5.7 Run OpenStack ansible script

        ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts openstack.yaml

## Note

1. How to purge OpenStack cluster.

        cd <glocalcache> ## you set <glocalcache> in group_vars/all before.
        source openstackvenv/bin/activate
        kolla-ansible -i kolla_ansible_inventory/multinode destroy --yes-i-really-really-mean-it
        deactivate

2. When you purge OpenStack cluser and want to deploy it again, you need to remove cinder-volumes in step 1.

    For example:

        vgremove -y cinder-volumes

3. You mighe have a hang issue when use comand like vgscan, pvscan, vgcreate. Reboot the server, the issue will gone.
