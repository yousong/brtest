#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#
#
# _netns_eth: interface from which address will be moved to ovsbr
#             notrack.sh also uses it to distinguish init_net and other namespaces
# _netns_npair: how many bridge members to create, ip's to configure
#
# _netns_network: first 24 bits for IP address of other end of the bridge ports
# _netns_ipstart: start  8 bits for IP address of other end of the bridge ports
# _netns_netmask: netmask used for routes to bridge ports
#

_initialize_netns() {
	_netns_eth=eth0

	_netns_npair=127
	_netns_network=10.0.77
	case "$hostself" in
		$host07)
			_netns_ipstart=1
			_netns_netmask="$_netns_network.0/25"
			;;
		$host08)
			_netns_ipstart=128
			_netns_netmask="$_netns_network.128/25"
			;;
		*)
			echo "$0: hostself is expected to be $host07 or $host08" >&2
			exit 254
			;;
	esac
}
_initialize_netns

# "ip netns" command can fail randomly on CentOS 6.6
ip_netns() {
	local i j=1

	for i in $(seq 1 3); do
		ip netns "$@" && return 0

		[ "$1" != "delete" ] && {
			sleep "$j"
			j="$(($j * 2))"
		}
	done

	return 1
}
