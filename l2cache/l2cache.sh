#!/bin/bash

get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    # SoCFPGA Stratix 10 SoCDK ==> 10SoCDK
    # SoCFPGA Agilex SoCDK ==> Agilex SoCDK
    cat /proc/device-tree/model | sed 's/Altera //' | cut -d ' ' -f 2-3 | tr -d ' '
}

get_l2aux_ctrl()
{
   dmesg | grep CACHE_ID | cut -d':' -f2 | cut -d' ' -f5
}

l2cache_test()
{
   machine_type="$(get_devkit_type)"
   echo "machine_type = $machine_type"

   if [ "$machine_type" == 'Stratix10' ] || [ "$machine_type" == 'AgilexSoCDK' ]; then
	echo "L2 Cache test is not applicable for Stratix10/Agilex"
	exit 1
   fi

   l2_cache_dmesg="$(dmesg | grep CACHE_ID | sed -r 's,\[[ 0-9.]*\] ,,')"
   echo "$l2_cache_dmesg"

   l2_auxval="$(get_l2aux_ctrl)"
   echo "L2 AUX_CTRL $l2_auxval"

   dprefetch=$(((l2_auxval >> $L310_AUX_CTRL_DATA_PREFETCH) & 1))
   echo "d_prefetch $dprefetch"

   iprefetch=$(((l2_auxval >> $L310_AUX_CTRL_INSTR_PREFETCH) & 1))
   echo "i_prefetch $iprefetch"

   shared_override=$(((l2_auxval >> $L2C_AUX_CTRL_SHARED_OVERRIDE) & 1))
   echo "shared-override $shared_override"

   evt_mon=$(((l2_auxval >> $L2C_AUX_CTRL_EVTMON_ENABLE) & 1))
   echo "evtmon $evt_mon"

   if [ "$dprefetch" == 1 ]; then
	if [ "$iprefetch" == 1 ]; then
	     if [ "$shared_override" == 1 ]; then
		status_fail=0;
	     else
		echo "Error, L2 SHARED OVERRIDE(bit 22) not set"
	     fi
	else
	     echo "Error, L2 INSTRUCTION PREFECTH(bit 29) not set"
	fi
   else
	echo "Error, L2 DATA PREFECTH(bit 28) not set"
   fi
}

#===========================================================
echo "L2-Cache AUX_CTRL test"
echo

L310_AUX_CTRL_DATA_PREFETCH=28
L310_AUX_CTRL_INSTR_PREFETCH=29
L2C_AUX_CTRL_SHARED_OVERRIDE=22
L2C_AUX_CTRL_EVTMON_ENABLE=20
status_fail=1

l2cache_test

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
