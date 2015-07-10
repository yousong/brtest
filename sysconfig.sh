#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

# - Setup hosts before running any test
# - This file works mainly as a memo of steps involved in configuring test machines
# - This script is not intended to be run blindly

rpm_download() {
	local nperf="netperf-2.6.0-1.el6.rf.x86_64.rpm"
	local iperf="iperf-2.0.5-11.el6.x86_64.rpm"

	# http://pkgs.repoforge.org/netperf/
	wget -c -O "$nperf" "http://pkgs.repoforge.org/netperf/$nperf"
	wget -c -O "$iperf" "ftp://rpmfind.net/linux/epel/6/x86_64/$iperf"
}

# install netperf
nperf="netperf-2.6.0-1.el6.rf.x86_64.rpm"
wget -c -O "$nperf" "http://pkgs.repoforge.org/netperf/$nperf"
sudo rpm -ihv "$nperf"

# install iperf
iperf="iperf-2.0.5-11.el6.x86_64.rpm"
wget -c -O "$iperf" "ftp://rpmfind.net/linux/epel/6/x86_64/$iperf"
sudo rpm -ihv "$iperf"

# install iproute with netns support from RDO repository
#
#  - https://spredzy.wordpress.com/2013/11/22/enable-network-namespaces-in-centos-6-4/
#  - http://www.xiaomastack.com/2015/04/05/centos6-ip-netns/
#
# Care should be take that `ip netns` command can fail randomly on CentOS 6.6
# (see env-netns.sh for details).  Rebooting the system may help in case that
# it fails so frequently that you cannot complete the environment setup with
# netns-env-xxx.sh
#
# The following is for CentOS 6.6.  CentOS 7 iproute comes with `ip netns`
# support by itself
sudo yum install -y https://repos.fedorapeople.org/repos/openstack/openstack-icehouse/rdo-release-icehouse-4.noarch.rpm
sudo yum install -y iproute
sudo yum install -y bridge-utils
#sudo yum install -y tunctl

# fetch test scripts
#rsync -aP rsync://172.30.10.157:7873/pub .

# irq affinity
sudo service puppet stop
sudo service irqbalance stop

device="eth0"
qints="$(cat /proc/interrupts | grep "$device" | cut -f1 -d:)"
sudo ./set_irq_affinity.sh "$device"
for i in $qints; do echo $i $(sudo cat /proc/irq/$i/smp_affinity{,_list}); done

# RSS
sudo ethtool -N eth0 rx-flow-hash udp4 sdfn
sudo ethtool -n eth0 rx-flow-hash udp4

# driver features
sudo ethtool -k eth0
sudo ethtool -K eth0 tx off
sudo ethtool -K eth0 rx off
sudo ethtool -K eth0 gso off
sudo ethtool -K eth0 gro off
sudo ethtool -k eth0

# handle TCP TIME_WAIT
sudo ./time-wait.sh setup

# setup notrack on host
sudo ./notrack.sh setup
sudo iptables -t raw -n -L -v

# enable ip_forward
sudo sh -c 'echo 1 >/proc/sys/net/ipv4/ip_forward'

#rsync rsync://172.30.10.157:7873/
#rsync -aP rsync://172.30.10.157:7873/pub .
