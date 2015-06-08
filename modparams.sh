#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#
# Sample run
#
#    ./modparams.sh ixgbe
#

_modparams() {
	# module
	local m="$1"
	# module path
	local mp="/sys/module/$m"
	# parameter path
	local pp="$mp/parameters"
	local param

	# not yet loaded?
	[ -d "$mp" ] || {
		echo "cannot find $mp" >&2
		return 1
	}
	# no param on load?
	[ -d "$pp" ] || {
		return 0
	}

	for param in $(ls "$pp"); do
		echo -n "$param=$(cat $pp/$param) "
	done
}

modparams() {
	local m

	for m in $*; do
		echo -n "$m: "
		_modparams "$m"
		echo
	done
}

if [ "$#" -gt 0 ]; then
	modparams "$@"
else
	modparams "$(cat /proc/modules | cut -f1 -d' ')"
fi
