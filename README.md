## This is a project to deploy OpenStack, ceph and intel IA feature PMEM
PMEM is an IA differentiate feature, all the support needed by the integration of pmem and openstack has been ready and ingetrated into this script, also the integration of OpenStack and Ceph. So after deployment with it, we can obtain a complete environment of OpenStack plus Ceph, with IA feature PMEM enabled in it.
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
	+ ceph_block_devices:
    +  `- /dev/sdb`
    +  `- /dev/sdc`
	+ ops_external_ceph: true
	+ ops_docker_registry: 10.67.125.31:4000
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

### Note

1. Before deploy OpenStack, please turn Intel Virtualization Technology (VT-x) on in your BIOS. You can use the command below to check whether VT is enabled or not.

        cat /proc/cpuinfo | grep vmx

2. When you have issues when deploying Ceph, please check the system time first. Sync time and try it again.

    For example:

        You might have a hang issue in below step:
            TASK [ceph-ansible : Perform the deployment for ceph cluster]

3. If your Ceph hosts < 3 hosts, please set ceph_osd_pool_default_size to < 3 to make pg's status active+clean.

4. Before purge OpenStack cluster, you need to kill qemu processes first. If not, it will have an error when purging OpenStack cluster.

    On OpenStack compute nodes:

        ps aux | grep qemu
        kill -9 <pid>

5. If some VMs are up and some VMs are not, please use the command below to check resources like disk/cpu/memory first. Lack of resources might lead to VMs' failure.

        nova  hypervisor-stats

### Reference docs

- [Kubernetes Deployment Doc](k8s-doc.md)
- [Memtier tests with pmem memory mode on Kubernetes cluster](memtier-k8s-doc.md)
- [How to run memtier tests on existing Kuberneters cluster](How_to_run_memtier_on_exsiting_k8s_cluster.md)
- [How to only deploy OpenStack](How_to_only_deploy_openstack.md)
- [Rally benchmark on VM](rally-doc.md)
- [Deploy Ceph with 1 device : multiple osds](Deploy_Ceph_with_1_dev_multi_osds.md)