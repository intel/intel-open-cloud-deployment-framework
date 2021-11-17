# How to run memtier benchmark on existing Kubernetes cluster

## Prerequisites
- An exsiting Kubernetes cluster.

    Currently, we only verified two scenarios:
    - Kubernetes cluster on Ubuntu18.04 deployed via kubeadm 
    - Kubernetes cluster on CentOS7 deployed via our Kubernetes ansible script
- OpenCloud deployment node on CentOS7


## Steps 
1. Create a common user with the same password for ansible on each node.
    
    For example:

        sudo useradd -m centos
        sudo passwd cento

2. As root user to add current user to /etc/sudoers on all nodes, add the following line into the bottom of /etc/sudoers on all nodes.

        sudo vim /etc/sudoers
            # Allow members of group sudo to execute any command
            %sudo   ALL=(ALL:ALL) ALL
            centos  ALL=(ALL)     NOPASSWD: ALL  ## add this line

3. Use k8s cluster via the common user.

    Node: k8s master node
    User: centos (created in step1)

        su centos  # switch to the user
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

4. Prepare OpenCloud on deployment node (CentOS7)

    4.1 Install tools

        sudo yum install git -y
        sudo yum install epel-release.noarch -y
        sudo yum install ansible -y
        sudo yum install python36 -y

    4.2 Clone OpenCloud repository

        git clone https://gitlab.devtools.intel.com/essprc/opencloud2.0.git

    4.3 Edit **inventory/hosts** to add IPs of k8s cluster and OpenCloud deployment node for ssh.

        [all_hosts]
	    10.1.1.1  # k8s master node
	    10.1.1.2  # k8s worker node
	    10.1.1.3  # k8s worker node
        10.1.2.1  # OpenCloud deployment node

    4.4 Config ssh (If we switch to new hosts, new config for hosts, we need to remove known_host file firstly)

        export ANSIBLE_HOST_KEY_CHECKING=False
        ansible-playbook -e ansible_ssh_user="centos" -e ansible_ssh_pass=<user_password> -i inventory/hosts ssh.yaml
        Note: use the user created in step1.
    
    4.5 Edit **inventory/hosts** for k8s and memtier

        [kubernetes_hosts]
	    10.1.1.1  # k8s master node
	    10.1.1.2  # k8s worker node
	    10.1.1.3  # k8s worker node
	
	    [kubernetes_master_hosts]
	    10.1.1.1  # k8s master node
	
	    [memtier_hosts]
	    10.1.1.2

        Note: the memtier pods and redis pods will run on memtier_hosts

    4.6 Edit **group_vars/all** for memtier

        Set memtier_redis_pods, memtier_pods and memtier_iter_no based on your hareware resources (CPU and Memory).

    4.7 Run memtier ansible script

        ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts memtier-k8s.yaml
    
    4.8 Get the performance result

        After running memtier-k8s.yaml, the final performance result will be printed on the screen.
        And if you want to recap the detailed full performance data, you can view the file: {{ local_temp }}/result-{{ memtier_pods }}-{{ memtier_iter_no }}
        eg: /tmp/result-150-1

## Issues and Solutions

- Issue1:

    Hang when creating redis and memtier pod.

    For example:

        	$ kubectl get pods
			NAME                              READY   STATUS              RESTARTS   AGE
			memtier-54cc84fcc7-d42zv          0/1     ContainerCreating   0          54s
            redis-0                           0/1     ContainerCreating   0          57s

    Solution:

        If the CPU and Memory resources you request in redis pod and memtier pod > avaiable CPU and Memory resources on your [memtier_hosts], it might have this hang issue.

        1) Please check CPU and Memory resource on [memtier_hosts]
            CPU CMD: cat /proc/cpuinfo
            Memory CMD: free
        2) Please check the CPU and Memory resource you request in redis-statefulset.yaml and memtier.yaml.

            resources:
              limits:
                cpu: "500m"
                memory: "12Gi"
              requests:
                cpu: "500m"
                memory: "1Gi"
        3) Change the CPU and Memory configuration in redis-statefulset.yaml and memtier.yaml based on the CPU and Memory resource on your [memtier_hosts].

- Issue2:

        TASK [memtier : debug] *******************************************************************************************************************************************************************
		ok: [10.1.1.2] => {
		    "msg": [
		        "memtier-54976cd9bc-mzg9w",
		        "redis-0.redis:6379: error: Temporary failure in name resolution",
		        "command terminated with exit code 1"
		    ]
        }

    Solution:

        1) Stop NetworkManager and restart docker on k8s cluster
            $ sudo systemctl stop NetworkManager
            $ sudo systemctl restart docker
        2) Wait the status of k8s cluster to be ok.
            $ kubectl get pods -o wide --all-namespaces
            # Note: All pods' status should be running.
        3) Run memtier ansible again.
