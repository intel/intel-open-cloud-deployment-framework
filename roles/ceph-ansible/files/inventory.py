#!/usr/bin/env python3
import configparser

import os
import sys
import random
import socket

CONFIG_FILE = os.environ.get("CONFIG_FILE", "hosts.ini")
CONFIGED_FILE = os.environ.get("CONFIGED_FILE", "hosts.yaml")

class CephInventory(object):

    def __init__(self, subnet, hosts=None, config_file=None, configed_file=None):
        self.config_file = config_file
        self.config = configparser.ConfigParser(allow_no_value=True)
        self.subnet = subnet

        if self.config_file:
            if not os.path.exists(self.config_file):
                print("{} not exist".format(self.config_file))
                sys.exit(1)
            try:
                self.config.read('./hosts.ini')
            except OSError:
                pass

        if hosts:
            hosts = self.range2ips(hosts)

        self.setips(hosts)
        self.subnet_mask(hosts) 
        #self.add_localhost()
        self.showconfig() 
        with open(configed_file, 'w') as configfile:
            self.config.write(configfile)

    def range2ips(self, hosts):
        reworked_hosts = []

        def ips(start_address, end_address):
            try:
                # Python 3.x
                start = int(ip_address(start_address))
                end = int(ip_address(end_address))
            except Exception:
                # Python 2.7
                start = int(ip_address(str(start_address)))
                end = int(ip_address(str(end_address)))
            return [ip_address(ip).exploded for ip in range(start, end + 1)]

        for host in hosts:
            if '-' in host and not (host.startswith('-') or host[0].isalpha()):
                start, end = host.strip().split('-')
                try:
                    reworked_hosts.extend(ips(start, end))
                except ValueError:
                    raise Exception("Range of ip_addresses isn't valid")
            else:
                reworked_hosts.append(host)
        return reworked_hosts

    def collectsections(self):
        sections = self.config.sections()
        return sections

    def setips(self, hosts):
        sections = self.collectsections()
        secs_num = len(sections)
        host_num = len(hosts)

        # put all hosts in every section
        for section in sections:
            for host in hosts:
                self.config.set(section, host)    

        '''
        # put a radom host from hosts in every section
        if secs_num >= host_num:
            unchanged = sections
            changed = hosts
            reverse = 0
        else:
            unchanged = hosts
            changed = sections
            reverse = 1

        num = 0
        for unchange in unchanged:
            if num <= 0:
                num = len(changed)
                change = changed.copy()

            index = random.randint(0,num-1)
            item = change[index]
            if reverse == 0:
                self.config.set(unchange, item)
            else:
                self.config.set(item, unchange)
            num = num -1
            change.remove(item)
        '''    

    def showconfig(self):
        for section in self.collectsections():
            print("{}: {}".format(section, self.config.items(section)))

    def subnet_mask(self, hosts):

        for host in hosts:
            self.subnet.append('.'.join(host.split('.')[:3]) + '.0')

        # remove duplicated one
        # insert the list to the set 
        subnet_set = set(self.subnet) 
        self.subnet = (list(subnet_set)) 
        subnet_len = len(self.subnet)

        if subnet_len != 1:
           print("The subnet mask is not unique, please confirm and try again")
           sys.exit(1)
        print("subnet_mask: {}/24".format(self.subnet[0]))

    def add_localhost(self):
        monitors = self.config.items('mons')

        try:
            host_name = socket.gethostname() 
            host_ip = socket.gethostbyname(host_name) 
            print("local ip   :", (host_ip, '')) 
            if (host_ip, '') not in monitors:
                self.config.set('mons', 'localhost')
        except: 
            print("Unable to get localhost Hostname and IP")
            sys.exit(1)

def main(argv=None):
    if not argv:
        argv = sys.argv[1:]
    subnet = []
    CephInventory(subnet, argv, CONFIG_FILE, CONFIGED_FILE)

if __name__ == "__main__":
    sys.exit(main())
