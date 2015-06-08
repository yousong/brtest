# Know more about the machines under test

## Sockets, cores, processors

CPU topology, supported features, etc.

- `lscpu`
	- Good summary text
- `/proc/cpuinfo`
	- `physical id`, socket index
	- `cpu cores`, total number of cores in a socket
	- `core id`, core index within a socket
	- `ht` within `flags` for hyperthreading
- `dmidecode -t processor`

[Intel Xeon E5-2650 v2](http://ark.intel.com/products/75269/Intel-Xeon-Processor-E5-2650-v2-20M-Cache-2_60-GHz) has 2 as the "Max CPU Configuration".  Sample output from `lscpu` on Linux with command line `maxcpus=16`

	[root@yf-mhost08 ~]# lscpu
	Architecture:          x86_64
	CPU op-mode(s):        32-bit, 64-bit
	Byte Order:            Little Endian
	CPU(s):                32
	On-line CPU(s) list:   0-15
	Off-line CPU(s) list:  16-31
	Thread(s) per core:    1
	Core(s) per socket:    8
	Socket(s):             2
	NUMA node(s):          2
	Vendor ID:             GenuineIntel
	CPU family:            6
	Model:                 62
	Stepping:              4
	CPU MHz:               2599.955
	BogoMIPS:              5199.24
	Virtualization:        VT-x
	L1d cache:             32K
	L1i cache:             32K
	L2 cache:              256K
	L3 cache:              20480K
	NUMA node0 CPU(s):     0,2,4,6,8,10,12,14
	NUMA node1 CPU(s):     1,3,5,7,9,11,13,15

Which cores are online/offline

	[root@yf-mhost08 ~]# ls -l /sys/devices/system/cpu/*line
	-r--r--r-- 1 root root 4096 Jun  8 12:05 /sys/devices/system/cpu/offline
	-r--r--r-- 1 root root 4096 Jun  3 22:56 /sys/devices/system/cpu/online

	cat /sys/devices/system/cpu/online
	cat /sys/devices/system/cpu/offline

Hotplug cores

	echo 1 >/sys/devices/system/cpu/cpu31/oneline
	echo 0 >/sys/devices/system/cpu/cpu31/oneline

### To disable HT

- [Comments from John D. McCalpin:](https://software.intel.com/en-us/comment/1761670#comment-1761670) in post "Impact disabling hyperthreading in linux"

	> Enabling or disabling HyperThreading has to be done by the BIOS.

- [Disabling hyperthreading in CentOS/RHEL Linux](http://www.bigdatamark.com/disabling-hyperthreading-in-centosrhel/)

	> if one can disable hyperthreading in the BIOS, one should try that first.

`maxcpus=` and `isolcpus=` in kernel command line

- `maxcpus` determines number of online CPUs that will be enabled by kernel
- `isolcpus`, will isolate the specified cores from scheduler by default.  Tasks can still be scheduled to those cores by explicitly setting CPU affinity mask.

To read current setting

	# maxcpus=16 isolcpus=0-7
	cat /proc/cmdline
	cat /boot/grub/grub.conf

Sample kernel command line option for DPDK

		maxcpus=16 isolcpus=0-7 numa=on default_hugepagesz=1G hugepagesz=1G hugepages=48

### Processes' CPU affinity

To check current default affinity setting

	{ sleep 1 & }; taskset -p $!

View last process's affinity

	#  mask
	taskset -p $!
	#  cpu list
	taskset -cp $!

Pin an existing process

	taskset -p 2ff $(pgrep -x iperf)
	taskset -cp 0-7,9 $(pgrep -x iperf)

Launch a program with desired affinity

	taskset 2ff iperf -s
	taskset -c 0-7,9 iperf -s

To check CPU affinity of `iperf`, `netperf`, `netserver`

	for i in $(pgrep -x iperf); do taskset -p $i; done
	for i in $(pgrep -x netperf); do taskset -p $i; done
	for i in $(pgrep -x netserver); do taskset -p $i; done

- How to run program or process on specific CPU cores on Linux, http://xmodulo.com/run-program-process-specific-cpu-cores-linux.html

## The card and the driver

What's available

	[sankuai@yf-mhost07 ~]$ lspci | grep -Ei '(network|ethernet)'
	01:00.0 Ethernet controller: Intel Corporation Ethernet Controller 10-Gigabit X540-AT2 (rev 03)
	01:00.1 Ethernet controller: Intel Corporation Ethernet Controller 10-Gigabit X540-AT2 (rev 03)
	07:00.0 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
	07:00.1 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
	42:00.0 Ethernet controller: Intel Corporation 82599ES 10-Gigabit SFI/SFP+ Network Connection (rev 01)
	42:00.1 Ethernet controller: Intel Corporation 82599ES 10-Gigabit SFI/SFP+ Network Connection (rev 01)

Which one does `eth0` correspond to

	[sankuai@yf-mhost07 ~]$ ls -l /sys/class/net/eth0/device
	lrwxrwxrwx 1 root root 0 Jul  7 15:07 /sys/class/net/eth0/device -> ../../../0000:01:00.0

- HowTo: Linux Show List Of Network Cards, http://xmodulo.com/how-to-find-ethernet-network-interface-card-information-in-linux.html
- Comparison between Intel 82599EB, 82599ES, X540-AT2, (Launch data, lithography and price are the main difference...) http://ark.intel.com/compare/32207,41282,60020

### ethtool

`ethtool` is good friend for playing with the device and its driver

To find driver info for the device

	sudo ethtool -i eth0

Check

- Various offloading features `-k`
- Tx, Rx, etc. ring sizes, `-g`
- `-n ethX rx-flow-hash` of `tcp4`, `udp4`
- MTU of the interface
- Flow Director

	1. Find default value

			modinfo ixgbe

	2. Check them in `/sys/module/ixgbe/params`

			./modparams.sh ixgbe

Details about the driver is available in `Documentation/networking/`

	➜  ~/linux git:(master) find Documentation -name 'ixg*'
	Documentation/networking/ixgbe.txt
	Documentation/networking/ixgb.txt
	Documentation/networking/ixgbevf.txt

`ixgbe` from Intel is special that RHEL may have incorporated many features not present in upstream.

	http://downloadmirror.intel.com/22919/eng/README.txt

### [set_irq_affinity.sh](https://gist.github.com/yousong/dedbe18a9dfaa383df4e)

Stop `puppet` and `irqbalance`.

- `irqbalance` has its own magic setting irq affinity
- `puppet` will try laborious to sync the system setting and bring up `irqbalance` if it is stopped

		sudo service puppet stop
		sudo service irqbalance stop

Stop `irqbalance` at boot.  Not recommended.

	sudo chkconfig --level 123456 irqbalance off

Distribute irq handling for queues of eth0 to all processors

	sudo bash set_irq_affinity.sh eth0

Check the result

	for i in $(seq 124 140); do echo $i $(sudo cat /proc/irq/$i/smp_affinity{,_list}); done
	for i in $(seq 124 140); do echo $i $(sudo cat /proc/irq/$i/smp_affinity{,_list}); done | sort -nk3

- How do I disable the irqbalance service in Red Hat Enterprise Linux? (has no info on `puppet`), https://access.redhat.com/solutions/7349

### On UDP RSS

- Slow Bandwidth/Performance Utilization while Using VXLAN, https://support.cumulusnetworks.com/hc/en-us/articles/202862933-Slow-Bandwidth-Performance-Utilization-while-Using-VXLAN
	Looks like the following statement is not entirely true.

	> When a fragmented UDP frame arrives at the host, Intel made the decision that
	> all UDP frames with the fragmentation bit set would arrive on CPU/queue 0
	> rather than on any of the other CPUs/queues. Because this decision may result
	> in out of order frames (which is especially bad when streaming video), Intel
	> decided to not perform RSS on any UDP traffic. TCP traffic will not have this
	> restriction by default.

	> Since STT (Stateless Transport Tunneling), another network overlay protocol,
	> has a header that looks like TCP, these encapsulated frames will be
	> classified as TCP by the Intel hardware and RSS will be performed without
	> noticing any loss of throughput.

- ixgbe: drop support for UDP in RSS hash generation, http://patchwork.ozlabs.org/patch/59235/

	> The packets will still be hashed on source and destination IPv4/IPv6 
	> addresses.  The change just drops reading the UDP source/destination 
	> ports since in the case of fragmented packets they are not available and 
	> as such were being parsed as IPv4/IPv6 packets.  By making this change 
	> the queue selection is consistent between all packets in the UDP stream.
	> 
	> The only regression I would expect to see would be in testing between 
	> two fixed systems since the IP addresses of the two systems would be 
	> fixed and so running multiple flows between the two would yield the same 
	>   RSS hash for multiple UDP streams.  As long as multiple ip addresses 
	> are used  you should see multiple RSS hashes generated and as such the 
	> load should still be distributed.

- Receive Side Scaling: figuring out how to handle IP fragments, http://adrianchadd.blogspot.hk/2014/08/receive-side-scaling-figuring-out-how.html

	Why TCP does not have such default setting

	> People don't want to flip off IPv4+TCP hashing as they're convinced that
	> the TCP MSS negotiation and path-MTU discovery stuff will prevent there
	> from being any IP fragmented TCP frames.

## Softwares

### The kernel

Which version are you using

	uname -a

What's the kernel configuration

	ls /boot/config-*

What's the kernel command line

	cat /proc/cmdline

Are you running a kernel configured with debugging and hacking features enabled?

- The Performance Impact of CONFIG_DEBUG_KERNEL, http://hildstrom.com/projects/aestest/

### QoS or traffic control

	tc qdisc show
	tc filter show

### Protocol stack

- SYN and backlog

		/proc/sys/net/core/somaxconn
		/proc/sys/net/ipv4/tcp_max_syn_backlog
		/proc/sys/net/ipv4/tcp_syncookies

- Orphans, locally closed, and unacknowledged

	- When to tell the network layers???

			/proc/sys/net/ipv4/tcp_retries1

	- The maximum number of times a TCP packet is retransmitted in ESTABLISHED state.
	- Defaults to 15

			/proc/sys/net/ipv4/tcp_retries2

	- Number of tries to write the buffer?
	- TCP_RTO_MIN being 200msec, TCP_RTO_MAX being 120sec
	- With exponential backoff, 8 will results in a ca. 100sec timeout
	- Looks like 8 is a factly minimal value from the code

			/proc/sys/net/ipv4/tcp_orphan_retries

			`tcp_orphan_retries()` in `net/ipv4/tcp_timer.c`

	- Timeout staying in FIN_WAIT_2 state before aborting the connection

			/proc/sys/net/ipv4/tcp_fin_timeout

- TIME_WAIT

	- Max number of timwait sockets held by system simultaneously

			/proc/sys/net/ipv4/tcp_max_tw_buckets

	- Allow to reuse TIME_WAIT sockets for new connections when it is safe from protocol viewpoint

			/proc/sys/net/ipv4/tcp_tw_reuse'

	- Fast recycling TIME_WAIT sockets

			/proc/sys/net/ipv4/tcp_tw_recycle'

Connection tracking on?

	nf_conntrack: table full, dropping packet.
	__ratelimit: 1009 callbacks suppressed
	nf_conntrack: table full, dropping packet.

Reference

- Clear explanation on `tcp_max_syn_backlog` and `somaxconn`, and notes on `tcp_syncookies`, http://www.beingroot.com/articles/apache/socket-backlog-tuning-for-apache
- on `tcp_tw_reuse`, `tcp_tw_recycle`, wrong in the case of `tcp_fin_timeout`, http://www.fromdual.com/huge-amount-of-time-wait-connections
- May contain errors, good as an auxiliary material though, https://www.frozentux.net/ipsysctl-tutorial/chunkyhtml/tcpvariables.html
- TCP Connection State Diagram, https://tools.ietf.org/html/rfc793#section-3.3

		ESTABLISHED
			FIN_WAIT_1
			FIN_WAIT_2
			TIME_WAIT

			CLOSE_WAIT
			LAST_ACK
		CLOSING
		CLOSED

### Test tools

- Care and Feeding of Netperf 2.6.X, http://www.netperf.org/svn/netperf2/tags/netperf-2.6.0/doc/netperf.html
- pktgen, `Documentation/networking/pktgen.txt`
- iperf

## Snippets belonging nowhere

on PAWS (protection against wrapped sequence)

	$ echo 'scale=3; 8 * 2^31 / 10^10' | bc
	1.717
	$ echo 'scale=3; 8 * 2^31 / 10^9' | bc
	17.179

	$ echo 'scale=3; 8 * 2^31 / (10^10 * (1500 - 16 - 20 -20) / 1500) ' | bc
	1.784
	$ echo 'scale=3; 8 * 2^31 / (10^9 * (1500 - 16 - 20 -20) / 1500) ' | bc
	17.846

`TCP_TIMEWAIT_LEN` is defined with value `60 * HZ`

What's the available memory modules

	sudo dmidecode -t 17 | grep 'Size: [0-9]\+ '

Dumb netcat (some other day will try `socat`)

	cat /dev/zero | nc -l 127.0.0.1 7001
	nc 127.0.0.1 7001 >/dev/null

Dumb `ethtool` and `ifconfig` commands

	for i in $(seq 0 5); do
	  sudo ethtool eth$i
	done

	sudo ifconfig eth2 10.0.0.77 up
	sudo ifconfig eth2 10.0.0.78 up

	ethtool -N eth0 rx-flow-hash udp4 sdfn
	ethtool -n eth0 rx-flow-hash udp4 sdfn

Bring down all those "link detection: no"

	for i in /sys/class/net/*; do
	  [ -f "$i/operstate" ] || continue
	  o=$(cat "$i/operstate")
	  echo "$(basename "$i")"
	  [ "$o" = "up" ] || sudo ifconfig "$(basename "$i")" up
	  sleep 2
	  c=$(cat "$i/carrier")
	  [ "$c" -gt 0 ] || sudo ifconfig "$(basename "$i")" down
	done

