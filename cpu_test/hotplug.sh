#!/bin/bash

get_cpu0()
{
   cat /proc/cpuinfo | cut -c-13 | grep processor | grep 0 | cut -d ':' -f 2
}

get_cpu1()
{
   cat /proc/cpuinfo | cut -c-13 | grep processor | grep 1 | cut -d ':' -f 2
}

shutdown_cpu1()
{
   echo 0 > /sys/devices/system/cpu/cpu1/online
}

bringup_cpu1()
{
   echo 1 >  /sys/devices/system/cpu/cpu1/online
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

hotplug_test()
{
   echo "Unplugging CPU1"

   shutdown_cpu1

   echo "Looking for CPU 1"
   cpu1_info="$(get_cpu1)"
   echo "CPU1: $cpu1_info"
   if [ -z "$cpu1_info" ]; then
	echo "Failed to see CPU1. CORRECT!"
	status_fail=0
   else
	status_fail=1
	return
   fi

   bringup_cpu1

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

cpu1_shutdown_str='CPU1: shutdown'
#===========================================================
echo "HOTPLUG test - Dynamically shutdown CPU1"
echo

if [ -z "$DEVNODE" ] || [ ! -e "$DEVNODE" ]; then
    echo "Error cannot find devnode $DEVNODE"
    exit 1
fi

smp_test
hotplug_test

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS - Able to hotplug CPU1"
else
    echo "FAIL - NOT able to hotplug CPU1"
fi

exit $status_fail
