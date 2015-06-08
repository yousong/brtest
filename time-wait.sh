#!/bin/bash -x
#
# Author: Yousong Zhou <yszhou4tech AT gmail.com>
#

. "$PWD/env.sh"

time_wait_setup() {
	sh -c 'echo 1      >/proc/sys/net/ipv4/tcp_tw_reuse'
	sh -c 'echo 1      >/proc/sys/net/ipv4/tcp_tw_recycle'
}

time_wait_teardown() {
	sh -c 'echo 0      >/proc/sys/net/ipv4/tcp_tw_reuse'
	sh -c 'echo 0      >/proc/sys/net/ipv4/tcp_tw_recycle'
}

if [ "$1" = "setup" ]; then
	time_wait_setup
else
	time_wait_teardown
fi
