#!/bin/sh
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
passwd root<<EOF
123456
123456
EOF
