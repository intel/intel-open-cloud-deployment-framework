#!/bin/bash

sudo -E yum -y update
sudo -E yum install passwd openssl openssh-server openssh-clients
sudo -E ssh-keygen -q -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N ''
sudo -E ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
sudo -E ssh-keygen -t dsa -f /etc/ssh/ssh_host_ed25519_key -N ''

sudo -E sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config

# sudo -E sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
sudo -E /usr/sbin/sshd -D &

ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub localhost
