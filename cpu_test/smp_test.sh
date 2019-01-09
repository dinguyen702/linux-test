#!/bin/bash

get_cpu0()
{
   cat /proc/cpuinfo | cut -c-13 | grep processor | grep 0 | cut -d ':' -f 2
}

get_cpu1()
{
   cat /proc/cpuinfo | cut -c-13 | grep processor | grep 1 | cut -d ':' -f 2
}

smp_test()
{
   echo "Looking for CPU 0"
   cpu0_info="$(get_cpu0)"

   echo "CPU0: $cpu0_info"
   if [ "$cpu0_info" -ne "$CPU0_INFO" ]; then
	echo "Failed to see CPU0. Expecting $CPU0_INFO"
	status_fail=1
	return
   fi

   echo "Looking for CPU 1"
   cpu1_info="$(get_cpu1)"

   echo "CPU1: $cpu1_info"
   if [ -z "$cpu1_info" ]; then
	echo "Failed to see CPU1. Expecting $CPU1_INFO"
	status_fail=1
	return
   fi
}

CPU0_INFO=0
CPU1_INFO=1
DEVNODE=/proc/cpuinfo
status_fail=0

#===========================================================
echo "SMP test - Looking for 2 CPUs"
echo

if [ -z "$DEVNODE" ] || [ ! -e "$DEVNODE" ]; then
    echo "Error cannot find devnode $DEVNODE"
    exit 1
fi

smp_test

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS - Found 2 CPUs"
else
    echo "FAIL - Could NOT find 2 CPUs"
fi

exit $status_fail
