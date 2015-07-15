#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

# Sum throughput result from iperf server logs
sum_iperf_srv() {
	cat "$__logdir/srv."* | grep -o '[0-9]\+ Kbits/sec' | cut -f1 -d' ' | paste -sd+ - | bc
}

# Sum throughput result from iperf client logs
sum_iperf_cln() {
	cat "$__logdir/cln".* | grep -o '[0-9]\+ Kbits/sec' | cut -f1 -d' ' | paste -sd+ - | bc
}

# Sum the ${1}th field from netperf logs
__sum_netperf_nth_field() {
	local nth="$1"; shift

	cat "$@" | tr -d '\r' | awk '
BEGIN { total=0; }
/^[0-9. ]+$/ {
  if ($'$nth' ~ /[0-9. ]+/) {
      total += $'$nth';
  }
}
END { printf("%.2f\n", total); }'
}

# Sum netperf RR result from logs
sum_netperf_rr_trans() {
	__sum_netperf_nth_field 6 "$@"
}

# Sum netperf throughput result from logs
sum_netperf_throughput() {
	__sum_netperf_nth_field 5 "$@"
}

_sum_from_test() {
	local t="$1"
	local action

	case "$t" in
		*RR)
			action=sum_netperf_rr_trans
			;;
		*STREAM)
			action=sum_netperf_throughput
			;;
		*)
			echo "unknown test type $t" >&2
			exit 254
			;;
	esac

	echo "$action"
}

# Sum result in logs $_out_raw.$s where $s is element in $_ssizes
# Result will be presented in 4 columns
#  - 1st column is the L4 payload size
#  - 2nd column is ethernet frame size by adding 58 (TCP: `20 + 20 + 18)` or 46 (UDP: `8 + 20 + 18`) to the value in 1st column
#  - 3rd column is the sum of reported result (throughput or tps) from netperf instance(s)
#  - 4th column is the calculated transmission rate (bits/s) based on the ethernet frame size and 3rd column result
sum_netperf_aggregate() {
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
