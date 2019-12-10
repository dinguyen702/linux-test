#!/bin/bash

get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    # SoCFPGA Stratix 10 SoCDK ==> 10SoCDK
    # SoCFPGA Agilex SoCDK ==> Agilex SoCDK
    cat /proc/device-tree/model | sed 's/Altera //' | cut -d ' ' -f 2-3 | tr -d ' '
}

get_kernel_version()
{
   uname -r | cut -c -4 | cut -c 1-3
}

clock_test()
{
case "$(get_devkit_type)" in
    ArriaV ) mpu_clk=$MPU_RATE_ARRIA5 ;;
    CycloneV ) mpu_clk=$MPU_RATE_CYCLONE5 ;;
    Arria10) mpu_clk=$MPU_RATE_ARRIA10 ;;
    Stratix10) mpu_clk=$MPU_RATE_STRATIX10 ;;
    AgilexSoCDK) mpu_clk=$MPU_RATE_AGILEX ;;
    * ) echo "unable to identify board. exiting." ; exit 1 ;;
esac
   machine_type="$(get_devkit_type)"
   echo "mpu_clk = $mpu_clk"

   echo "machine_type = $machine_type"

   kernel_version="$(get_kernel_version)"

   echo "kernel version = $kernel_version"
   

   echo "Read frequency of $OSC_CLK"
   CMD="cat /sys/kernel/debug/clk/$OSC_CLK/clk_rate"
   echo "$CMD"
   clk_rate=$($CMD)
   ret=$?

   if [ "$ret" != '0' ]; then
	echo "FAIL - return code is $ret"
	return $ret
   fi

   echo "clock rate of $OSC_CLK = $clk_rate"
   if [ "$clk_rate" != "$OSC_RATE" ]; then
	echo "Error, incorrect clock rate. Expecting $OSC_RATE"
	status_fail=1
	return
   fi

   echo "Read frequency of $MPU_CLK"
   if [ "$machine_type" == 'Arria10' ]; then
	CMD="cat /sys/kernel/debug/clk/$MPU_A10_CLK/clk_rate"
   elif [ "$machine_type" == 'Stratix10' ]; then
	CMD="cat /sys/kernel/debug/clk/$MPU_S10_CLK/clk_rate"
   elif [ "$machine_type" == 'AgilexSoCDK' ]; then
	CMD="cat /sys/kernel/debug/clk/$MPU_S10_CLK/clk_rate"
   else
	CMD="cat /sys/kernel/debug/clk/$MPU_CLK/clk_rate"
   fi
   echo "$CMD"
   clk_rate=$($CMD)
   ret=$?

   if [ "$ret" != '0' ]; then
	echo "FAIL - return code is $ret"
	return $ret
   fi

   echo "clock rate of $MPU_CLK = $clk_rate"
   if [ "$clk_rate" != "$mpu_clk" ]; then
        echo "Error, incorrect clock rate. Expecting $mpu_clk"
	status_fail=1
        return
   fi
}

OSC_CLK=osc1
MAINPLL_CLK=main_pll
MPU_CLK=mpuclk
MPU_A10_CLK=mpu_free_clk
MPU_S10_CLK=mpu_clk
DEVNODE=/sys/kernel/debug/clk
status_fail=0

OSC_RATE=25000000
MPU_RATE_CYCLONE5=925000000
MPU_RATE_ARRIA5=1050000000
MPU_RATE_ARRIA10=1200000000
MPU_RATE_STRATIX10=1000000000
MPU_RATE_AGILEX=1000000000

#===========================================================
echo "Clock driver test"
echo

if [ -z "$DEVNODE" ] || [ ! -e "$DEVNODE" ]; then
    echo "Error cannot find devnode $DEVNODE"
    exit 1
fi

clock_test

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
