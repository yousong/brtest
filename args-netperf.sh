#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

_args_nshift=0
while getopts 't:n:l:T:H:' _args_opt; do
	case "$_args_opt" in
		t)
			# what test to run
			_test="$OPTARG"
			;;
		n)
			# how many instances to start
			_nwnd="$OPTARG"
			;;
		l)
			# how long (time, transactions, bytes)
			__testlen="$OPTARG"
			;;
		T)
			# test specific options to pass
			_testopt="$OPTARG"
			;;
		H)
			# - where will netservers be started
			# - where will netperfs connect to
			_ovss="$OPTARG"
			;;
	esac
	_args_nshift="$(( $_args_nshift + 2 ))"
done
shift "$_args_nshift"

_args_dirfix="${_testopt}"
_args_dirfix="${_args_dirfix//-/}"
_args_dirfix="${_args_dirfix// /}"
_args_dirfix="${_args_dirfix:+-$_args_dirfix}"

__logdir="$__logdir-$_test-H${_ovss}-n${_nwnd}l${__testlen}$_args_dirfix"

# Ignore -r option in STREAM test
_args_rrsize() {
	local s="$1"
	local arg

	case "$_test" in
		*RR)
			arg="-r $s"
			;;
		*STREAM)
			;;
		*)
			echo "unknown test type $_test" >&2
			;;
	esac

	echo "$arg"
}
