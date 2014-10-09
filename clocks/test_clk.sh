#!/bin/bash

get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    cat /proc/device-tree/model | cut -d ' ' -f 3-4 | tr -d ' '
}

clock_test()
{
case "$(get_devkit_type)" in
    ArriaV ) mpu_clk=$MPU_RATE_ARRIA5 ;;
    CycloneV ) mpu_clk=$MPU_RATE_CYCLONE5 ;;
    * ) echo "unable to identify board. exiting." ; exit 1 ;;
esac
   echo "mpu_clk = $mpu_clk"

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
   CMD="cat /sys/kernel/debug/clk/$OSC_CLK/$MAINPLL_CLK/$MPU_CLK/clk_rate"
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
DEVNODE=/sys/kernel/debug/clk
status_fail=0

OSC_RATE=25000000
MPU_RATE_CYCLONE5=925000000
MPU_RATE_ARRIA5=1050000000

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
