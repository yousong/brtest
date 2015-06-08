#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

# Execute command(s) $2 on host $1
remote_cmd() {
	local h="$1"
	local cmd="$2"

	echo "$cmd" | ssh -t -i "$__identity" "$__username@$h" 'bash -s'
}

# Stop all existing iperf on "$@"
stop_iperf() {
	local h

	for h in "$@"; do
		remote_cmd "$h" 'sudo kill -HUP $(pgrep -x iperf);'
	done 2>/dev/null
}

# Stop all existing netserver, netperf on "$@"
stop_netperf() {
	local h

	for h in "$@"; do
		remote_cmd "$h" 'sudo kill -HUP $(pgrep -x netserver); sudo kill -HUP $(pgrep -x netperf);'
	done 2>/dev/null
}

__reset_session() {
	local nwnd2="${1:-0}"
	local i

	# reset screen session
	screen -S "$__session_name" -X quit
	screen -d -m -s /bin/bash -S "$__session_name"

	# make total nwnd2 windows
	for i in $(seq 2 $nwnd2); do
		screen -S "$__session_name" -X screen
	done

	# reset $__logdir
	rm -rf "$__logdir"
	mkdir -p "$__logdir"
}

reset_session() {
	__reset_session "$@" &>/dev/null
}

_ssizes_from_test() {
	local t="$1"
	local _ssizes

	case "$t" in
		TCP_*)
			_ssizes="6 70 198 454 966 1222 1460 8960 65495"
			;;
		UDP_*)
			_ssizes="18 82 210 466 978 1234 1472 8972 65507"
			;;
		*)
			echo "unknown test type $t" >&2
			;;
	esac

	echo "$_ssizes"
}

_hlen_from_test() {
	local t="$1"
	local hlen

	case "$t" in
		TCP_*)
			# TCP options may present most of the time
			hlen=$((20 + 20 + 18))
			;;
		UDP_*)
			hlen=$((20 + 8 + 18))
			;;
		*)
			hlen=0
			echo "unknown test type $t" >&2
			;;
	esac

	echo "$hlen"
}
