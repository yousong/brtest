#!/bin/bash -x
#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

#
# Test with netperf on 2 physical hosts
#
#  - defaults to UDP_CRR test
#  - start $_nwnd netserver on $_ovss
#  - start $_nwnd client on $hostself
#
# Prepare test environment with
#
# Traffic path
#
#       $ipself   <->    $ippeer
#
# Sample run
#
#    sudo ./t-host-netperf.sh -t TCP_CRR -H 10.4.22.19 -T '-b 100' run
#    sudo ./t-host-netperf.sh -t TCP_CRR -H 10.4.22.19 -T '-b 100' sum
#

. "$PWD/env.sh"

_nwnd="${_nwnd:-32}"
_test="${_test:-UDP_RR}"
_ovss="${_ovss:-$ippeer}"

# sum or run, remember to take the same arguments on each run
. "$TOPDIR/args-netperf.sh"

_ssizes="$(_ssizes_from_test "$_test")"
_out_raw="$__logdir/test_throughput_frame_size.raw.data"

runtest() {
	local prcr
	local port
	local s i

	stop_netperf "$ip07" "$ip08"
	reset_session

	# 4. kick _nwnd xperf server
	for i in $(seq 0 $(($_nwnd - 1))); do
		prcr="$(( $i % $__nprcr ))"
		port="$(($__nperf_sport + $i))"

		ssh -i "$__identity" "$__username@$_ovss" taskset -c "$prcr" netserver -p "$port"
	done

	# 5. wait for servers to start
	sleep 1

	# run test with different message size
	# $s is currently not relevant in STREAM test
	for s in $_ssizes; do
		for i in $(seq 0 $(($_nwnd - 1))); do
			prcr="$(( $i % $__nprcr ))"
			port="$(($__nperf_sport + $i))"

			taskset -c "$prcr" netperf -H "$_ovss" -p "$(($__nperf_sport + $i))" -l "$__testlen" -t "$_test" -- $_testopt $(_args_rrsize "$s") &
		done >"$_out_raw.$s"
		# wait for the result
		wait
	done
}

summary() {
	local s
	local frame_size total_trans rate
	local hlen="$(_hlen_from_test "$_test")"
	local sum_action="$(_sum_from_test "$_test")"

	for s in $_ssizes; do
		frame_size="$(($s + $hlen))"
		total_trans="$($sum_action "$_out_raw.$s")"
		rate="$(echo "$frame_size * 8 * $total_trans" | bc )"
		echo "$s $frame_size $total_trans $rate"
	done | column -t
}

main "$@"
