# The whole OpenStack deployment process includes common environment setting, intel special environment setting, OpenStack deployment, and OpenStack resource preparation.
This is a project to deploy OpenStack via Kolla-Ansible method.

Kolla-Ansible's mission statement is:

    - Kolla-Ansible deploys OpenStack services and infrastructure components in Docker containers.

Getting Started:

    - Learn about OpenStack-Deployment by reading this documentation.

Infrastructure components:

    - Prepare common environment

    - Prepare intel special environment, due to network problems, so this item could be removed when applied to customer's env

    - Use virtual env to deploy OpenStack

    - Prepare multinode file and global.yml for kolla-ansible deployment method, and this deployment suppose Ceph is ready

    - According to community's step to deploy OpenStack

    - After OpenStack deployment successes, OpenStack resource will be prepared for VM usage, including network, flavors, images, volumes, and VMs

    - VM creation includes common VMs and special PMEM VMs

    - And you can run the top openstack.yaml to run the scripts. Also we could run the sub-modules via seperated yaml files

Usage:

    - Please modify the inventory/hosts according to real env

    - Please specify VM related parameters in group_vars/all or roles/defaults/main.yaml before using


Directories:

├── group_vars
│   └── all
├── inventory
│   └── hosts
├── openstack.yaml
├── ops-deploy.yaml
├── opsenv-pre.yaml
├── README.md
└── roles
    ├── common
    │   └── tasks
    │       └── main.yaml
    ├── exnet-enable
    │   └── tasks
    │       ├── external_net.yaml
    │       └── main.yaml
    ├── ops-deploy
    │   ├── defaults
    │   │   └── main.yaml
    │   ├── files
    │   │   └── source
    │   │       ├── kolla-9.2.0.tar.gz
    │   │       └── kolla-ansible-9.2.0.tar.gz
    │   ├── tasks
    │   │   ├── configini.yaml
    │   │   ├── configrepo.yaml
    │   │   ├── dependency.yaml
    │   │   ├── deploy.yaml
    │   │   ├── docker.yaml
    │   │   └── main.yaml
    │   ├── templates
    │   │   └── globals.j2
    │   └── vars
    │       └── main.yaml
    ├── opsenv-net
    │   └── tasks
    │       ├── main.yaml
    │       └── tap.yaml
    ├── opsenv-pre
    │   ├── defaults
    │   │   └── main.yaml
    │   ├── files
    │   │   └── updateyumresource.sh
    │   ├── tasks
    │   │   ├── common_env.yaml
    │   │   ├── intel_env_allnode.yaml
    │   │   └── main.yaml
    │   └── templates
    │       ├── docker_proxy.j2
    │       └── global_proxy.j2
    ├── post-deploy
    │   ├── defaults
    │   │   └── main.yaml
    │   ├── files
    │   │   ├── generaterc.sh
    │   │   └── prepare_resource.sh
    │   ├── tasks
    │   │   ├── main.yaml
    │   │   ├── ops_res.yaml
    │   │   └── post_dpl.yaml
    │   └── tool
    │       └── prepare_resource.sh
    └── vms-op
        ├── defaults
        │   └── main.yaml
        ├── files
        │   ├── common_vm_create.sh
        │   ├── delete_vms.sh
        │   └── pmem_vm_create.sh
        └── tasks
            ├── main.yaml
            ├── vms_create.yaml
            └── vms_delete.yaml


