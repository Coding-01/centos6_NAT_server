OS:
centos6.8

server IP:
eth0   xxx.xx.xxx.xx         //Public network IP
eth1   172.16.1.1            //local area network IP

server:
vim /etc/sysconfig/network-scripts/ifcfg-eth0
IPADDR=<Public network IP>            
NETMASK=<Public network netmask>

cp ifcfg-eth0 ifcfg-eth1

vim /etc/sysconfig/network-scripts/ifcfg-eth1
HWADDR=00:0C:29:20:42:76
IPADDR=172.16.1.1           
NETMASK=255.255.255.0

ifup eth1

SERVER GATEWAY config:
vim /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=gateway
GATEWAY=<public gateway>

SERVER DNS config:
vim /etc/resolv.conf
nameserver <public DNS1> 
nameserver <public DNS2>

SERVER Kernel optimization:
vin /etc/sysctl.conf 
net.ipv4.ip_forward = 1           
fs.nr_open = 2048576
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_symack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_tw_buckets = 81920
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_restries2 = 10
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_rmem = 4096  16777216 33554432
net.ipv4.tcp_wmem = 4096  16777216 33554432
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.core.somaxconn = 32768
net.core.rmem_default = 335544320
net.core.wmem_default = 83886000
net.core.rmem_max = 335544320
net.core.wmem_max = 83886000
net.core.netdev_max_backlog = 100000
net.nf_connteack_max = 25000000
net.netfilter.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_tcp_timeout_established = 7200
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 128
net.netfilter.nf_conntrack_tcp_timeout_close_wait 60
.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120

sysctl -p 
Note: After executing this command, you should see the information without error or other warnings.

DISABLE selinux: (C/S All disable)
setenforce 0
vim /etc/selinux/config                 
SELINUX=disabled 

SERVER:
vim gateway.sh
#!/bin/bash
FILE=/opop/mac_new.txt
modprobe iptable_nat
modprobe ip_conntrack
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
iptables -F INPUT
iptables -F OUTPUT
iptables -F FORWARD
iptables -t nat -F
iptables -t nat -X
iptables -F
iptables -X
#iptables -A INPUT -p tcp -s 192.168.0.49 --dport 1082 -j ACCEPT
#iptables -A INPUT -p 22 -j ACCEPT
#iptables -A INPUT -p 22 -j DROP
#iptables -A INPUT -j DROP
#iptables -A INPUT -p tcp --dport 1082 -j DROP
cat $FILE | while read ipad mac
do
    iptables -A FORWARD -s $ipad -m mac --mac-source $mac -j ACCEPT
    arp -s $ipad $mac 
done
 
#iptables -A FORWARD -o eth1 -m state --state  ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -m iprange --src-range 172.168.1.1-172.16.1.254 -j SNAT --to <Public network ip>
#iptables -t nat -A PREROUTING -i eth0 -d <Public network ip> -p tcp --dport 80 -j DNAT --to-destination 192.168.0.140:80
#iptables -t nat -I POSTROUTING -d <Public network ip> -p tcp --dport 80 -j SNAT --to 192.168.0.140:80
#iptables -A FORWARD -o eth1 -d 192.168.0.140 -p tcp --dport 80 -j ACCEPT
#iptables -A FORWARD -i eth1 -s 192.168.0.140 -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -o eth1 -m state --state  ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -j DROP
service iptables save
chkconfig iptables on 
 
#############################################################################################
 
[root@bogon opop]# chmod +x gateway.sh  
[root@bogon opop]# vim mac_new.txt
     
    format：172.16.1.15     00:0c:29:93:70:dd 

Refresh gateway.sh:
[root@bogon opop]# ./gateway.sh

vim /etc/crontab
0 0 6 * * root ntpdate -s time.windows.com
[root@gateway ~]# service ntpd start       
 
[root@gateway ~]# vim /etc/security/limits.conf
     
    * soft   nofile   32768
    * hard   nofile   65536

[root@gateway ~]# shutdown -r now            
[root@gateway ~]# ulimit -n                 
[root@gateway ~]# ulimit -a                 
 
######################################################################################
 
start test：
 
open centos6 test：
vim /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
HWADDR=00:0C:29:D3:9F:8E
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=static        
IPADDR=172.16.1.20
NETMASK=255.255.255.0
GATEWAY=172.16.1.1	//server eth1 addr
DNS1=<Public network DNS1>
DNS2=<Public network DNS2>


service network restart
 
 
ping 172.16.1.1
ping www.baidu.com
dig www.baidu.com 


open win10 start test：
IP ADDRESS：172.16.1.30   
netmask：255.255.255.0
default gateway：<server eth1 IP>
DNS1：<public network DNS1>        
DNS2：<public network DNS2>

open cmd window
ping 172.16.1.1
ping www.baidu.com
nslookup www.baidu.com
