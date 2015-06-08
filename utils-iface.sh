#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

resolve_ip() {
	local h="$1"
	local ip

	# It is possible that your corporate DNS server does not serve
	# DNS requests from $_netns_netmask (within namespaces).
	#
	# If that is the case, you can replace here with a case statement.
	#ip="$(host "$h" | grep -o -m1 ' [0-9.]\+$')"
	#ip="${ip# }"
	#echo "$ip"

	h="${h#yf-mhost0}"
	h="${h#yf-mhost}"
	h="$(($h + 9))"
	echo "10.4.22.$h"
}

# Get IPv4 address of the interface with netmask
#
# Result has the form: 10.4.22.17/24
_iface_addr() {
	local ifname="$1"

	ip addr show dev "$ifname" | grep -o 'inet [0-9.]\+/[0-9]\+' | cut -f2 -d' '
}

# Convert from integer netmask to dot-separated netmask value
#
# Example: with 25 as the 1st argument, the result will be 255.255.255.128
_n2mask() {
	local n="$1"
	local netmask
	local i j

	n="$(( 2**32 - (1<<(32 - $n)) ))"
	for i in $(seq 0 8 24); do
		j="$(( ($n >> $i) & 255 ))"
		netmask="$j.$netmask"
	done
	echo "${netmask%.}"
}

# Fetch the IPv4 address of the specified interface
#
# Result has the form: 10.4.22.17
iface_addr() {
	local ifname="$1"

	_iface_addr "$ifname" | cut -f1 -d/
}

# Fetch the IPv4 address of the specified interface
#
# Result has the form: 255.255.255.128
iface_mask() {
	local ifname="$1"
	local nmask

	nmask="$(_iface_addr "$ifname" | cut -f2 -d/)"
	_n2mask "$nmask"
}

# - Move IPv4 Address from device $1 to $2
# - Install a default route on device $2
iface_move_addr() {
	local sdev="$1"
	local ddev="$2"
	local addr mask

	addr="$(iface_addr "$sdev")"
	mask="$(iface_mask "$sdev")"
	[ -n "$addr" -a -n "$mask" ] || return 1
	ifconfig "$sdev" 0.0.0.0
	ifconfig "$ddev" "$addr" netmask "$mask"
	ip route add default dev "$ddev" via "${addr%.*}.1"
}
