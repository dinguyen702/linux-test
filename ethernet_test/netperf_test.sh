#!/bin/bash

# Start netserver on host with:
# netserver -p 1234

TEST_RESULTS="netperf_test.txt"
HOST_ADDR="192.168.1.101"
SELF="$(basename $0)"
DIRSELF="$(dirname $0)"

usage()
{
    cat <<EOF
Capture the Kernel Version and ifconfig settings then
Run the Ethernet tests
Capture the Ethtool settings.
Saving everything into a local file for attaching to test page.

Usage: $(basename $0) [-h] [-a <host address>]

i.e.:
 $  $(basename $0)
  Execute the test with default host address ${HOST_ADDR}

 $  $(basename $0) -a 192.168.1.2
  Execute the test with passed in host address 192.168.1.2

 $  $(basename $0) -h
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

echo "uname -a" | tee ${TEST_RESULTS}
uname -a | tee -a ${TEST_RESULTS}
echo  | tee -a ${TEST_RESULTS}
echo "-------------------------------------------------" | tee -a ${TEST_RESULTS}

sleep 1
echo "ifconfig eth0" | tee -a ${TEST_RESULTS}
ifconfig eth0 | tee -a ${TEST_RESULTS}
echo  | tee -a ${TEST_RESULTS}
echo "-------------------------------------------------" | tee -a ${TEST_RESULTS}

sleep 1
echo "TCP Performance" | tee -a ${TEST_RESULTS}
echo " => netperf -H ${HOST_ADDR}" | tee -a ${TEST_RESULTS}
netperf -H ${HOST_ADDR} | tee -a ${TEST_RESULTS}
echo
echo "-------------------------------------------------" | tee -a ${TEST_RESULTS}

sleep 1
echo "UDP Stream Performance" | tee -a ${TEST_RESULTS}
echo " => netperf -H ${HOST_ADDR} -t UDP_STREAM -- -m 1024" | tee -a ${TEST_RESULTS}
netperf -H ${HOST_ADDR} -t UDP_STREAM -- -m 1024 | tee -a ${TEST_RESULTS}
echo
echo "-------------------------------------------------" | tee -a ${TEST_RESULTS}


sleep 1
echo "TCP Request/Response Performance" | tee -a ${TEST_RESULTS}
echo " => netperf -H ${HOST_ADDR} -t TCP_RR" | tee -a ${TEST_RESULTS}
netperf -H ${HOST_ADDR} -t TCP_RR | tee -a ${TEST_RESULTS}
echo
echo "-------------------------------------------------" | tee -a ${TEST_RESULTS}

sleep 1
echo "UDP Request/Response Performance" | tee -a ${TEST_RESULTS}
echo " => netperf -H ${HOST_ADDR} -t UDP_RR" | tee -a ${TEST_RESULTS}
netperf -H ${HOST_ADDR} -t UDP_RR | tee -a ${TEST_RESULTS}
echo
echo "-------------------------------------------------"

sleep 3
echo "Dump Ethernet Stats" | tee -a ${TEST_RESULTS}
echo "ethtool -S eth0" | tee -a ${TEST_RESULTS}
ethtool -S eth0 | tee -a ${TEST_RESULTS}
echo "-------------------------------------------------"

sleep 3
echo "Dump Ethernet Registers" | tee -a ${TEST_RESULTS}
echo "ethtool -d eth0" | tee -a ${TEST_RESULTS}
ethtool -d eth0 | tee -a ${TEST_RESULTS}
echo "-------------------------------------------------"

