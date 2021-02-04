#/bin/bash

# System eniroment
#CentOS Linux release 7.7.1908 (Core)
#Linux fearfst 3.10.0-1062.el7.x86_64 

yum install wget -y

# Install epel-release
wget -c https://mirrors.ustc.edu.cn/epel/epel-release-latest-7.noarch.rpm -O /tmp/epel-release-latest-7.noarch.rpm 
rpm -ivh /tmp/epel-release-latest-7.noarch.rpm

# Replace the original url with ustc
sed -e 's|^metalink=|#metalink=|g' \
    -e 's|^#baseurl=https\?://download.fedoraproject.org/pub/epel/|baseurl=https://mirrors.ustc.edu.cn/epel/|g' \
    -i.bak \
    /etc/yum.repos.d/epel.repo

sudo sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://mirrors.ustc.edu.cn/centos|g' \
         -i.bak \
         /etc/yum.repos.d/CentOS-Base.repo

yum repolist

# Install Ansible
yum install ansible -y

# Install python3.6
yum install python36 -y
