#!/bin/bash

# This test runs a series of netperf tests for tracking Ethernet performance

status_fail=0

HOST_ADDR="192.168.1.101"
readonly SELF="$(basename $0)"
readonly DIRSELF="$(dirname $0)"

usage()
{
    cat <<EOF
To run this test, a netserver must be running on the HOST PC as
the other side of this transaction.
Start the netwerver on the host PC with:
# netserver -p 1234

This test will:
Capture the Kernel Version and ifconfig settings then
Run the Ethernet tests
Capture the Ethernet configuration using Ethtool.
It is useful to capture the output by piping to a tee file.
${SELF} 2>&1 | tee <output_file>.txt

Usage: ${SELF} [-h] [-a <host address>]

i.e.:
 $  ${SELF}
  Execute the test with default host address ${HOST_ADDR}

 $  ${SELF} -a 192.168.1.2
  Execute the test with passed in host address 192.168.1.2

 $  ${SELF} -h
  Print this message.

EOF
}

while [ -n "$1" ]; do
    case $1 in
	-h|--help ) usage ; exit ;;
	-a|--addr ) HOST_ADDR=$2; shift ;;
	* ) echo "unknown parameter: $1" ; echo ; usage ; exit ;;
    esac
    shift
done

function netperf_test::netperf_results ()
{
    CMD="$1"
    THRESHOLD="$2"
    #echo "Command: ${CMD}"
    netperf=$(${CMD})
    ret=$?

    if [ "${ret}" != '0' ]; then
	echo "FAIL - return code is ${ret}"
	status_fail=1
    fi

    echo "${netperf}"
    # Throughput is the last field on the 7th line. Use rev to flop, cut, reverse again and trim.
    throughput=$(echo "${netperf}" | head -7 | tail -1 | rev | cut -c -12 | rev | tr -d '[:space:]')
    throughput=$(printf "%.0f\n" "${throughput}")
    echo "^^^^^^^^^^^^^^^^^^"
    echo "Throughput number is ${throughput}"

    if [ "${throughput}" -lt "${THRESHOLD}" ]; then
	echo "Error, Didn't meet threshold value of ${THRESHOLD}."
	status_fail=1
    else
	echo "Passed threshold value of ${THRESHOLD}"
    fi
}


echo "Kernel Version: `uname -a`"
echo
echo "-------------------------------------------------"

sleep 1
set -x; ifconfig eth0; set +x
echo
echo "-------------------------------------------------"

sleep 1
echo "TCP Performance"
NP_CMD="netperf -H ${HOST_ADDR}"
echo " => ${NP_CMD}"
# Send netperf_results command with COMMAND and minimum threshold value
netperf_test::netperf_results "${NP_CMD}" 750
echo
echo "-------------------------------------------------"

sleep 1
echo "UDP Stream Performance"
NP_CMD="netperf -H ${HOST_ADDR} -t UDP_STREAM -- -m 1024"
echo " => ${NP_CMD}"
# Send netperf_results command with COMMAND and minimum threshold value
netperf_test::netperf_results "${NP_CMD}" 500
echo
echo "-------------------------------------------------"

sleep 1
NP_CMD="netperf -H ${HOST_ADDR} -t TCP_RR"
echo " => ${NP_CMD}"
# Send netperf_results command with COMMAND and minimum threshold value
netperf_test::netperf_results "${NP_CMD}" 1200
echo
echo "-------------------------------------------------"

sleep 1
NP_CMD="netperf -H ${HOST_ADDR} -t UDP_RR"
echo " => ${NP_CMD}"
# Send netperf_results command with COMMAND and minimum threshold value
netperf_test::netperf_results "${NP_CMD}" 1200
echo
echo "-------------------------------------------------"

sleep 3
echo "Dump Ethernet Stats"
set -x; ethtool -S eth0; set +x;
echo "-------------------------------------------------"

sleep 3
echo "Dump Ethernet Registers"
set -x; ethtool -d eth0; set +x;
echo "-------------------------------------------------"

echo
if [ "${status_fail}" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit ${status_fail}
