# How to test etcd in Kubernetes cluster

## Prerequisites
- All nodes on CentOS7


## Steps 
### 1. Mount HDD/SSD device to /var/lib/etcd
    
    For example:
        sudo mkdir -p /var/lib/etcd
	    sudo mkfs.xfs /dev/sdb -f  ## format device to xfs
        sudo mount -t xfs /dev/sdb /var/lib/etcd

### 2. Deploy kubernertes cluster. Refer [Kubernetes Deployment Doc](k8s-doc.md)

### 3. Install etcd benchmark tool on client node

    3.1 Install golang

        $ wget https://golang.org/dl/go1.16.7.linux-amd64.tar.gz
	    $ sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.16.7.linux-amd64.tar.gz
	
	    $ sudo vim /etc/profile
            ## add this line in the end.
	        export PATH=$PATH:/usr/local/go/bin
	
	    $ source /etc/profile
	    $ go version  # check version


    3.2 Install benchamrk tool 

        	git clone https://github.com/etcd-io/etcd.git
	        cd etcd/
            ## the etcd deployed by step2 is 3.4 version
            git checkout release-3.4
            go build -v ./tools/benchmark
            ## check the benchmark binary file 
            ls -lrt
            sudo cp benchmark /usr/local/go/bin/

### 4. How to do tests

    4.1 Copy cacert, key, cert files from k8s cluster to client node.

        scp -r /etc/ssl/etcd/ssl/ca.pem <client_node>
        scp -r /etc/ssl/etcd/ssl/node-node1.pem <client_node>
        scp -r /etc/ssl/etcd/ssl/node-node1-key.pem <client_node>

        Note:
            Here node1 is the hostname of one node of the k8s cluster.
    
    4.2 Check the leader of etcd cluster on k8s master node

        # change user to root
        etcdctl endpoint status -w table --cluster --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/node-node1.pem --key=/etc/ssl/etcd/ssl/node-node1-key.pem
            +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
            |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
            +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
            | https://10.1.1.1:2379 | 12814ef0e7744c12 |   3.4.3 |  7.4 MB |     false |      false |         6 |     348048 |             348048 |        |
            | https://10.1.1.2:2379 | 5ab45eced5b6d6e4 |   3.4.3 |  7.4 MB |      true |      false |         6 |     348048 |             348048 |        |
            | https://10.1.1.3:2379 | 85e9d45a8153be31 |   3.4.3 |  7.4 MB |     false |      false |         6 |     348048 |             348048 |        |
            +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    
    4.3 do tests on client node

        Write:
            ## target-leader
            benchmark --cacert=ca.pem --cert=node-node1.pem --key=node-node1-key.pem --endpoints=https://10.1.1.1:2379 --target-leader --conns=1 --clients=1 put --key-size=8 --sequential-keys --total=100 --val-size=256
            ## all members
            benchmark --cacert=ca.pem --cert=node-node1.pem --key=node-node1-key.pem --endpoints=https://10.1.1.1:2379,https://10.1.1.2:2379,https://10.1.1.3:2379 --conns=100 --clients=1000 put --key-size=8 --sequential-keys --total=100000 --val-size=256

        Read:
            ## Linearizable
            benchmark --cacert=ca.pem --cert=node-node1.pem --key=node-node1-key.pem --endpoints=https://10.1.1.1:2379,https://10.1.1.2:2379,https://10.1.1.3:2379 --conns=100 --clients=1000 range foo --consistency=l --total=100000
            ## Serializable
            benchmark --cacert=ca.pem --cert=node-node1.pem --key=node-node1-key.pem --endpoints=https://10.1.1.1:2379,https://10.1.1.2:2379,https://10.1.1.3:2379 --conns=100 --clients=1000 range foo --consistency=s --total=100000


