#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path/to/kubespray>"
    echo "    Example: $0 /opt/intel/kubespray"
    exit 1
fi

venv=${TARGETENV}
if [ ! -d ${venv} ]; then
    echo "virtual env ${venv} does not exist, abort..."
    exit 1
fi

repodir=$1
temp=${LOCALTEMP}
if [ ! -d ${repodir} ]; then
    echo "${repodir} does not exist, abort..."
    exit 1
fi

# active virtual env
source ${venv}/bin/activate

# upgrade pip 9.0.3 to >=19.1.1, use pip==9.0.3 will have an issue.
pip3 install -I 'pip>=19.1.1'

if [ -f "${repodir}/requirements.txt" ]; then
    pip3 install -r ${repodir}/requirements.txt
fi

ansible-playbook -i ${repodir}/inventory/mycluster/hosts.yaml \
  --become --become-user=root ${repodir}/cluster.yml > ${temp}/kubespray_deploy.log
