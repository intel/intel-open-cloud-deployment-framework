## This is a project to deploy OpenStack, ceph and intel IA feature PMEM
### Environment setup before running the scripts



- We should better sync time zone on all the 6 nodes(If timezone is unified when installing OS, please omit this step), use command such as:

	`$ timedatectl set-timezone Asia/Shanghai`
	
- Sync time on all the 6 nodes, it is necessary, use command:
	
	`$ ntpdate <ntp_server>`
- If ntpdate is not installed, we can install it via command:
	
	`$ yum install ntpdate -y`
- As root user to add current user to /etc/sudoers on all the 6 nodes, add the following line into the bottom of /etc/sudoers

	`[root@controller2 centos]# vi /etc/sudoers`

	`centos        ALL=(ALL)       NOPASSWD: ALL`

### For all the following steps, please do the operation on the deployment node. And do the operation as common user, such as: centos
- Switch to current user (eg: centos) and install tools on deployment node only:

	`$ sudo yum install git -y`

	`$ sudo yum -y install epel-release.noarch`

	`$ sudo yum -y install ansible -y`

	`$ sudo yum install python36 -y`
- Clone opencloud_ansible repository:

	`$ git clone https://gitlab.devtools.intel.com/essprc/opencloud2.0.git`
- The end user could edit **inventory/hosts** to set hosts according to actual cluster usage
+ The end user could edit **group_vars/all** for env setting, just an exmple as below:
    + glocalcache: /home/centos/intel/
	+ glocaltemp: /tmp
	+ ceph_network_ifg: eno1
	+ ceph_block_device: /dev/sdb
	+ ops_external_ceph: true
	+ ops_docker_registry: 10.67.125.21:4000
	+ ops_kolla_internal_vip_address: 10.67.125.123
	+ ops_network_interface: eno1
	+ glance_image_path: "/home/centos/workspace/centos7.qcow2"
	+ enable_docker_repo: false
	+ vm_start_timeout: 100
	+ vm_pmem_enabled: true

- Please put centos7.qcow2 on the deployment node: /home/centos/workspace/centos7.qcow2

- Config ssh (If we switch to new hosts, new config for hosts, we need to remove known_host file firstly):

	`$ export ANSIBLE_HOST_KEY_CHECKING=False`

	`$ ansible-playbook -e ansible_ssh_user="centos" -e ansible_ssh_pass=host_passwd -i inventory/hosts ssh.yaml`

- Run the exact deployment for PMEM, CEPH and OpenStack:

	`$ ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts pmem-openstack.yaml`

	`$ ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts ceph-openstack.yaml`
	
	`$ ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts openstack.yaml`

- After deployment, please reboot neutron servers(This is a limitation due to a bug of Centos7):
	
    `$ reboot`

- Switch to the path <kolla_ansible_install_path>/tools, such as: /home/centos/intel/kolla-ansible/tools, execute command:

	`$ ./kolla-ansible mariadb_recovery -i ../../multinode`