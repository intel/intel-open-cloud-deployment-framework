# Rally benchmark on VM

## Prerequisites
- OpenStack cluser

    You can use our OpenStack ansible script to deploy OpenStack or Ceph+OpenStack on CentOS7

## Steps 
1. Create a common user with the same password for ansible on each node. 

    Ignore it if you already use our ansible script to deploy OpenStack or Ceph+OpenStack.
    
    For example:

        sudo useradd -m centos
        sudo passwd cento

2. As root user to add current user to /etc/sudoers on all nodes, add the following line into the bottom of /etc/sudoers on all nodes.

    Ignore it if you already use our ansible script to deploy OpenStack or Ceph+OpenStack.

        sudo vim /etc/sudoers
            # Allow members of group sudo to execute any command
            %sudo   ALL=(ALL:ALL) ALL
            centos  ALL=(ALL)     NOPASSWD: ALL  ## add this line

3. Prepare OpenCloud on your OpenStack deployment node.

    3.1 Install tools

        sudo yum install git -y
        sudo yum install epel-release.noarch -y
        sudo yum install ansible -y
        sudo yum install python36 -y

    3.2 Clone OpenCloud repository

        git clone https://gitlab.devtools.intel.com/essprc/opencloud2.0.git

    3.3 Edit **inventory/hosts** to add IPs of all hosts for ssh.

    Ignore it if you already use our ansible script to setup ssh on all nodes.

    For example:

        [all_hosts]
	    10.1.1.1  # Deployment node, the deployment node and OpenStack controller node can be the same node
	    10.1.1.2  # OpenStack controller node
	    10.1.1.3  # OpenStack compute node
	    10.1.1.4  # OpenStack compute node

    3.4 Config ssh (If we switch to new hosts, new config for hosts, we need to remove known_host file firstly)

        export ANSIBLE_HOST_KEY_CHECKING=False
        ansible-playbook -e ansible_ssh_user="centos" -e ansible_ssh_pass=<user_password> -i inventory/hosts ssh.yaml
        Note: use the user created in step1.
    
    3.5 Edit **inventory/hosts** for Rally on OpenStack deployment node.

        [deployment_host]
        localhost

    3.6 Edit **group_vars/all** for Rally based on your OpenStack env

        # Setup rally
        #rally_repository: https://github.com/openstack/rally.git
        #rally_version: 3.3.0
        #rally_ops_env: /etc/kolla/admin-openrc.sh # Here is the openstack env script deployed by kolla-ansible
        
        # Setup rally task configuration
        #rally_flavor_name: "m1.small" # openstack flavor
        #rally_runner_times: 200       # set it based on your hardware resources
        #rally_concurrency: 100        # set it based on your hardware resources
        #rally_image_name: "Centos"    # openstack image name

    3.7 Run Rally ansible script

        ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts rally.yaml
