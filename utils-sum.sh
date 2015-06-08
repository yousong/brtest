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
