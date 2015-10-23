#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

TOPDIR="$PWD"
# ovs-vsctl and other userspace tools are instaled in /usr/loca/bin
export PATH="/usr/local/bin:$PATH"

##
## - Variables starting with 2 consecutive underscores are from env.sh here
## - Variables starting with 1 underscore are test-local variables
##

# screen session name
__session_name=ovsperf
# newline for stuffing into shell cmdline within screen window
NL="$(echo -ne '\015')"


# where to put log files, this can be assigned with another value in t-xxx-xxx.sh file.
__logdir="$TOPDIR/logs.$(basename "$0")"


# ssh -i "$__identity" $__username@host
__username="yousong"
# identity file used to login into all hosts
__identity="/home/yousong/brtest/ovs.id_rsa"


# iperf start port
__iperf_sport=5001


# netperf start port
__nperf_sport=12865
# netperf -b option for RR test
# -b has no effect on TCP_CRR
__nperf_burst="${__nperf_burst:-100}"
# netperf -l option (run for 30 seconds)
__testlen="${__testlen:-30}"


# number of processors available on current host
__nprcr="$(cat /proc/cpuinfo  | grep '^processor' | wc -l)"


. "$TOPDIR/utils-session.sh"
. "$TOPDIR/utils-iface.sh"
. "$TOPDIR/utils-sum.sh"

host07=yf-mhost09
host08=yf-mhost10
__initialize() {
	ip07="$(resolve_ip "$host07")"
	ip08="$(resolve_ip "$host08")"
	[ -n "$ip07" -a -n "$ip08" ] || {
		echo "resolving ip address failed: $host07, $host08" >&2
		exit 254
	}

	hostself="$(hostname | cut -f1 -d.)"
	case "$hostself" in
		$host07)
			hostpeer="$host08"
			ipself="$ip07"
			ippeer="$ip08"
			;;
		$host08)
			hostpeer="$host07"
			ipself="$ip08"
			ippeer="$ip07"
			;;
		*)
			echo "$0: hostself is expected to be $host07 or $host08" >&2
			exit 254
			;;
	esac

	cat >&2 <<EOF
Host and IP detection result summary:

	hostself: $hostself
	hostpeer: $hostpeer
	ipself: $ipself
	ippeer: $ippeer

	host07: $host07
	hostpeer: $hostpeer
	ip07: $ip07
	ippeer: $ippeer
EOF
}
__initialize

runtest() { true; }
summary() { true; }
main() {
	case $1 in
		run)
			runtest
			;;
		sum)
			summary
			;;
		*)
			echo "run or sum?" >&2
			return 1
			;;
	esac
}
