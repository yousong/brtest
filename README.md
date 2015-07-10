Scripts mainly for testing bridge implementations (Linux bridge and Open vSwitch).

## Files

Parameters for running test

	args-netperf.sh
	env.sh
	env-netns.sh

Key pair for logging into test machines.  *Use them in this repo only if your test machines are secure and safe within internal network!*

	ovs.id_rsa								private identity key
	ovs.id_rsa.pub							public key

Rsync config file for loading myself into test machines

	rsyncd.conf

Utils functions that can be sourced (no function execution would happen there)

	utils-session.sh
	utils-iface.sh
	utils-sum.sh

Util scripts for setting up bridge `ovsbr` for testing.  Note that `ovsbr` is just the name of the bridge interface.  It can be of type Linux bridge.

	netns-env-bridge.sh
	netns-env-ovs-internal.sh
	netns-env-ovs-veth.sh

Util scripts

	modparams.sh							check kernel module parameters
	notrack.sh								enable/disable connection track on flows involved in the test
	set_irq_affinity.sh						imported utility script for binding NIC queues' irq affinity to processor cores
	sysconfig.sh							reference script for configuring test machines
	time-wait.sh							enable/disable tcp_tw_recycle and tcp_tw_reuse

4 test modes that can be run (details can be found in comments within each file)

	t-localhost-iperf.sh
	t-host-iperf.sh
	t-host-netperf.sh
	t-netns-netperf-bridge.sh

## How to use (port) it

Facts about tests in this project

- They happen between at most 2 physical hosts.
- Net namespaces are used in `t-netns-xxx.sh` tests.
- Configuring the two hosts before running any tests is a necessary step for consistent result between different runs
	- Commands in `sysconfig.sh` can serve as a reference
- Netperf 2.6.0 is used for most of the time
- Iperf2 is only used in TCP bulk transfer test for comparison with netperf

Preparation steps for `env.sh`

1. Set shell variables `host07`, `host08` in `env.sh`.  They are the 2 hosts involved in tests
2. Check if the following variables can get a correct value

		ip07, ip08
		hostself, hostpeer
		ipself, ippeer

3. Set variable `__username` for logging into `host07` and `host08`
4. Set variable `__identity` as the path to the identity file for passwordless login with ssh
5. Remember to copy public key corresponding to `$__identity` to `authorized_keys` of `$__username` and set appropriate permission bits

`env-netns.sh` contains parameters for setting up bridges and their port members.  Details can be found in the code comments there.

## Sample runs

Tests

	t-host-iperf.sh
	# Sample run
	#
	#    ./t-host-iperf.sh -n 20 run
	#    ./t-host-iperf.sh -n 20 sum
	
	t-host-netperf.sh
	# Sample run
	#
	#    sudo ./t-host-netperf.sh -t TCP_CRR -H 10.4.22.19 -T '-b 100' run
	#    sudo ./t-host-netperf.sh -t TCP_CRR -H 10.4.22.19 -T '-b 100' sum
	
	t-localhost-iperf.sh
	# Sample run
	#
	#    ./t-localhost-iperf.sh
	#
	
	t-netns-netperf-bridge.sh
	# Sample run
	#
	#    sudo ./t-netns-netperf-bridge.sh -t TCP_CRR -H 10.4.22.18 -n  1 -T '-b 100' run
	#    sudo ./t-netns-netperf-bridge.sh -t TCP_CRR -H 10.4.22.18 -n  1 -T '-b 100' sum

Bridge setup and teardown (teardown is implicit)

	./netns-env-bridge.sh setup
	./netns-env-bridge.sh

For `*RR` type tests, 4 columns are presented in the `sum` (summary) output

- 1st column is the value used for `-r`
- 2nd column is ethernet frame size by adding 58 (TCP: `20 + 20 + 18)` or 46 (UDP: `8 + 20 + 18`) to the value in 1st column
- 3rd column is the sum of reported tps (transaction per second) value from netperf instance(s)
- 4th column is the calculated transmission rate (bits/s) based on the ethernet frame size and tps

Some test results are collected in `out/` directory
