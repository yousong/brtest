#!/bin/bash -x
#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#
# Create Linux brige ovsbr for testing
#
#  - Create $_netns_npair net namespaces
#  - Create Linux bridge ovsbr
#  - Create $_netns_npair veth interfaces
#    - ovsvethN-0 is in init_net as member of ovsbr
#    - ovsvethN-1 is in init_net as member of ovsbr
#  - Setup addresses and routes so that $ippeer can be accessed from net
#    namespaces
#

. "$PWD/env.sh"
. "$PWD/env-netns.sh"

ovs_br_setup() {
	local network="$_netns_network"
	local netmask="$_netns_netmask"
	local ipstart="$_netns_ipstart"
	local ippeer="$ippeer"
	local device netns
	local i

	./notrack.sh setup
	brctl addbr ovsbr
	ip link set ovsbr up

	for i in $(seq 0 $(($_netns_npair - 1))); do
		device="ovsveth$i"
		netns="ovsnet$i"

		ip link add "$device-0" type veth peer name "$device-1"

		ip_netns add "$netns" || exit 1
		ip link set "$device-1" netns "$netns"
		ip_netns exec "$netns" ip addr add "$network.$(($ipstart + $i))" dev "$device-1"
		ip_netns exec "$netns" ip link set "$device-1" up
		ip_netns exec "$netns" ip route add default dev "$device-1"
		ip_netns exec "$netns" ./notrack.sh setup

		ip link set "$device-0" up
		brctl addif ovsbr "$device-0"
	done
	iface_move_addr "eth0" "ovsbr"
	ip route add "$netmask" dev ovsbr			# forward to $netns
	ip route add "$network.0/24" dev "ovsbr" via "$ippeer"		# forward to peer
	brctl addif ovsbr eth0

	remote_cmd "$ippeer" "sudo ip route add $netmask via '$ipself'"
}

ovs_br_teardown() {
	local network="$_netns_network"
	local netmask="$_netns_netmask"
	local ipstart="$_netns_ipstart"
	local ippeer="$ippeer"
	local device netns
	local i

	iface_move_addr "ovsbr" "eth0"
	ifconfig ovsbr down
	brctl delbr ovsbr
	for i in $(seq 0 $(($_netns_npair - 1))); do
		device="ovsveth$i"
		netns="ovsnet$i"

		ip link del "$device-0"
		ip_netns delete "$netns"
	done

	remote_cmd "$ippeer" "sudo ip route del $netmask via '$ipself'"
	./notrack.sh

	# it takes a while for the machinary to cool down
	sleep 2
}

ovs_br_teardown
if [ "$1" = "setup" ]; then
	ovs_br_setup
fi

