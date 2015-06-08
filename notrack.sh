#!/bin/bash -x
#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

. "$PWD/env.sh"
. "$PWD/env-netns.sh"

_notrack_action() {
	local action="$1"

	# exclude ourself from conntrack if I am part of init_net
	ip link show "$_netns_eth" &>/dev/null && {
		iptables -t raw $action PREROUTING -p tcp -d "$ipself" -j NOTRACK
		iptables -t raw $action OUTPUT -p tcp -s "$ipself" -j NOTRACK
	}

	# disable conntrack within net namespaces, including init_net
	iptables -t raw $action PREROUTING -p tcp -d "$_netns_network.0/24" -j NOTRACK
	iptables -t raw $action OUTPUT -p tcp -s "$_netns_network.0/24" -j NOTRACK
}

notrack_setup() {
	_notrack_action -A
}

notrack_teardown() {
	_notrack_action -D
}

notrack_teardown
if [ "$1" = "setup" ]; then
	notrack_setup
fi
