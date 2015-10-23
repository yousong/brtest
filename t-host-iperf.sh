#!/bin/bash -x
#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

# Test TCP bulk transfer with iperf
#
# Sample run
#
#    ./t-host-iperf.sh -n 20 run
#    ./t-host-iperf.sh -n 20 sum
#

. "$PWD/env.sh"

__nwnd="${_nwnd:-16}"

_args_nshift=0
while getopts 't:n:' _args_opt; do
	case "$_args_opt" in
		n)
			_nwnd="$OPTARG"
			_args_nshift=$(($_args_nshift + 2))
			;;
		t)
			__testlen="$OPTARG"
			_args_nshift=$(($_args_nshift + 2))
			;;
	esac
done
shift "$_args_nshift"

__logdir="$__logdir-$_nwnd"

_nwnd2="$(($_nwnd * 2))"
# screen has 40 as the limit for maximum number of windows by default.
if [ "$_nwnd2" -gt 40 ]; then
	echo "$0: Have you compiled a screen supporting more than 40 windows?" >&2
fi

screen_pane_srv() {
	local ip="$1"
	local port="$2"
	local prcr="$3"
	local idx="$4"

	local wnd="$idx"
	local logf="$__logdir/srv.$idx"
	local sshcmd="ssh -t -i '$__identity' $__username@$ip 'bash -s'"

	screen -S "$__session_name" -p "$wnd" -X logfile "$logf"
	screen -S "$__session_name" -p "$wnd" -X log on

	screen -S "$__session_name" -p "$wnd" -X stuff "echo 'taskset -c "$prcr" iperf -s -f k -p $port;'"
	screen -S "$__session_name" -p "$wnd" -X stuff " | $sshcmd $NL"
}

screen_pane_cln() {
	local cip="$1"
	local sip="$2"
	local port="$3"
	local prcr="$4"
	local idx="$5"

	local wnd="$(($_nwnd + $idx))"
	local logf="$__logdir/cln.$idx"
	local cmd="ssh -t -i '$__identity' $__username@$cip taskset -c "$prcr" iperf -c $sip -f k -p "$port" -t $__testlen"

	screen -S "$__session_name" -p "$wnd" -X logfile "$logf"
	screen -S "$__session_name" -p "$wnd" -X log on

	screen -S "$__session_name" -p "$wnd" -X stuff "$cmd$NL"
}

runtest() {
	local ovss="$ippeer"
	local ovsc="$ipself"
	local prcr port

	stop_iperf "$ippeer" "$ipself"
	reset_session "$_nwnd2"

	# 4. kick _nwnd xperf server
	for i in $(seq 0 $(($_nwnd - 1))); do
		prcr="$(($i % $__nprcr))"
		port="$(($__iperf_sport + $i))"

		screen_pane_srv "$ovss" "$port" "$prcr" "$i"
	done

	# 5. wait for the server to start
	sleep 1

	# 6. start _nwnd xperf client
	for i in $(seq 0 $(($_nwnd - 1))); do
		prcr="$(($i % $__nprcr))"
		port="$(($__iperf_sport + $i))"

		screen_pane_cln "$ovsc" "$ovss" "$port" "$prcr" "$i"
	done

	# it takes a while for the test to complete
}

summary() {
	sum_iperf_srv
	sum_iperf_cln
}

main "$@"
