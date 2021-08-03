# Memtier tests with pmem memory mode on Kubernetes cluster

## Prerequisites
- Follow Kubernetes Deployment Doc to set pmem mode to memory mode and deploy Kubernetes cluster.

## How to run memtier tests with pmem memory mode on Kubernetes cluster
1. Edit **inventory/hosts** to set memtier_hosts
    
    For example:

        [memtier_hosts]
        10.1.1.4
        10.1.1.5
        10.1.1.6
    Note: The hosts in memtier_hosts should be one or multiple hosts of pmem_hosts.

2. Edit **group_vars/all** to set configuration for memtier tests.

    Based on your CPU and Memory on your memtier_hosts to set redis pod and memtier pod quantities.

    For example:

        # Set redis pod quantity for memtier
        memtier_redis_pods: 150 # This value should be align with memtier_pods

        # Set memtier pod quantity
        memtier_pods: 150

        # Set memtier benchmark iteration number, only for tracking
        memtier_iter_no: 3

3. Run memtier tests

    `$ ansible-playbook -e ansible_ssh_user="centos" -i inventory/hosts memtier-k8s.yaml`
