# Kubernetes Deployment Doc
    
## Prerequisites
- Install CentOS-7 OS on all nodes

## How to deploy Kubernetes
### 1. Environment setup before running the scripts on all nodes
- We should better sync time zone on all nodes(If timezone is unified when installing OS, please omit this step), use command such as:

	`$ timedatectl set-timezone Asia/Shanghai`
- Sync time on all nodes, it is necessary, use command:
	
	`$ ntpdate <ntp_server>`
- If ntpdate is not installed, we can install it via command:
	
	`$ yum install ntpdate -y`
- Create a common user such as 'centos' for deployment. If you create a common user when install OS, please omit this step.

    `sudo useradd -m centos`

    `sudo passwd centos`
- As root user to add current user to /etc/sudoers on all nodes, add the following line into the bottom of /etc/sudoers

	`[root@controller2 centos]# vi /etc/sudoers`

	`centos        ALL=(ALL)       NOPASSWD: ALL` ## Add this line under "%wheel  ALL=(ALL)       ALL"

### 2. For all the following steps, please do the operation on the deployment node. And do the operation as common user, such as: centos
- Switch to current user (eg: centos) and install tools on deployment node only:

    `# su centos`

	`$ sudo yum install git -y`

	`$ sudo yum -y install epel-release.noarch`

	`$ sudo yum -y install ansible -y`

	`$ sudo yum install python36 -y`

- Git clone opencloud ansible repository:

	`$ git clone https://gitlab.devtools.intel.com/essprc/opencloud2.0.git`

- The end user could edit **inventory/hosts** to set hosts according to actual cluster usage

     You need to set deployment_host, ssh_hosts, kubernetes_hosts, kubernetes_master_hosts, kubernetes_worker_hosts.

     If you use pmem devices on nodes, you can also set pmem_hosts.

     Set Kubernetes master nodes via kubernetes_master_hosts
     Set Kubernetes worker nodes via kubernetes_worker_hosts

     An example:

        [all_hosts]
	    10.1.1.1
	    10.1.1.2
	    10.1.1.3
	    10.1.1.4
	    10.1.1.5
	    10.1.1.6
        
        [controller_hosts]
	    10.1.1.1
	    10.1.1.2
	    10.1.1.3
        
        [compute_hosts]
	    10.1.1.4
	    10.1.1.5
	    10.1.1.6
        
        [deployment_host]
        localhost
        
        [pmem_hosts:children]
        compute_hosts
        
        [ssh_hosts:children]
        all_hosts
        
        [kubernetes_hosts:children]
        all_hosts
        
        [kubernetes_master_hosts:children]
        controller_hosts
        
        [kubernetes_worker_hosts:children]
        compute_hosts
        
- The end user could edit **group_vars/all** for env setting, just an exmple as below:

        glocalcache: /home/centos/intel/
        glocaltemp: /tmp
        enable_docker_repo: false
        pmem_mode: Memory  ## Here we use Pmem Memory mode
        ceph_network_ifg: ens260f0  ## Make sure the network interfaces of all nodes are the same.
        ceph_block_devices:
          - /dev/nvme1n1  ## Make sure there're /dev/nvme1n1 on all nodes.
          - /dev/nvme2n1  ## Make sure there're /dev/nvme2n1 on all nodes.
        vm_start_timeout: 10
        disable_network_manager: true ## Need to disable network manager for Kubernetes deployment.

- Config ssh (If we switch to new hosts, new config for hosts, we need to remove known_host file firstly):

	`$ export ANSIBLE_HOST_KEY_CHECKING=False`

	`$ ansible-playbook -e ansible_ssh_user="centos" -e ansible_ssh_pass=host_passwd -i inventory/hosts ssh.yaml`

- Run ansible deployment for Kubernetes.

    - Do some setups on baremetal.

        `$ ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts baremetal-k8s.yaml `

    - Set Memory mode for pmem. You need to set pmem_mode to Memory mode in group_vars/all

        `$ ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts pmem-k8s.yaml`

    - Deploy Kubernetes cluster.

        `$ ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts k8s.yaml`
