#!/bin/bash
#
# Test compute capacity of the running host.
#
# - Result will be reported every 5 seconds
# - Stop it anytime with Ctrl-C
#
# Running this on different hosts can help decide if test machines were all
# configured correctly by cross check the result.
#
# Sample run
#
#    ./t-localhost-iperf.sh
#

iperf -s --daemon
iperf -c 127.0.0.1 -t 3600 -i 5

kill -KILL $(pgrep iperf)
