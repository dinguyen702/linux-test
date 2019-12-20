#!/bin/bash

get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    # SoCFPGA Stratix 10 SoCDK ==> 10SoCDK
    # SoCFPGA Agilex SoCDK ==> Agilex SoCDK
    cat /proc/device-tree/model | sed 's/Altera //' | cut -d ' ' -f 2-3 | tr -d ' '
}

get_cpu0()
{
   cat /proc/cpuinfo | cut -c-13 | grep processor | grep 0 | cut -d ':' -f 2
}

get_cpu1()
{
   cat /proc/cpuinfo | cut -c-13 | grep processor | grep 1 | cut -d ':' -f 2
}

get_cpu2()
{
   cat /proc/cpuinfo | cut -c-13 | grep processor | grep 2 | cut -d ':' -f 2
}

get_cpu3()
{
   cat /proc/cpuinfo | cut -c-13 | grep processor | grep 3 | cut -d ':' -f 2
}

smp_test()
{
   machine_type="$(get_devkit_type)"
   echo "machine_type = $machine_type"

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

   if [ "$machine_type" == 'Stratix10' ] || [ "$machine_type" == 'AgilexSoCDK' ]; then
      echo "Looking for CPU 2"
      cpu2_info="$(get_cpu2)"

      echo "CPU2: $cpu2_info"
      if [ -z "$cpu2_info" ]; then
        echo "Failed to see CPU2. Expecting $CPU2_INFO"
        status_fail=1
        return
      fi

      echo "Looking for CPU 3"
      cpu3_info="$(get_cpu3)"

      echo "CPU3: $cpu3_info"
      if [ -z "$cpu3_info" ]; then
        echo "Failed to see CPU3. Expecting $CPU3_INFO"
        status_fail=1
        return
      fi
   fi
}

CPU0_INFO=0
CPU1_INFO=1
CPU2_INFO=2
CPU3_INFO=3
DEVNODE=/proc/cpuinfo
status_fail=0

#===========================================================
echo "SMP test - Looking for 2/4 CPUs"
echo

if [ -z "$DEVNODE" ] || [ ! -e "$DEVNODE" ]; then
    echo "Error cannot find devnode $DEVNODE"
    exit 1
fi

smp_test

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS - Found 2/4 CPUs"
else
    echo "FAIL - Could NOT find 2/4 CPUs"
fi

exit $status_fail
