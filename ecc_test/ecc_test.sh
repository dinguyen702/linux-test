#!/bin/bash

status_fail=0


# First read all the ce_counts
if [ -e /sys/devices/system/edac/mc/mc0/ce_count ]; then
	echo "Read # of Correctable Errors on SDRAM Mem Controller"
	cat /sys/devices/system/edac/mc/mc0/ce_count
	cat /sys/devices/system/edac/mc/mc0/ce_count > sdram_cecount_orig.txt
fi
if [ -e /sys/devices/system/edac/l2edac/l2edac0/ce_count ]; then
	echo "Read # of Correctable Errors on L2 Cache"
	cat /sys/devices/system/edac/l2edac/l2edac0/ce_count
	cat /sys/devices/system/edac/l2edac/l2edac0/ce_count > l2_cecount_orig.txt
fi
if [ -e /sys/devices/system/edac/ocramedac/ocramedac0/ce_count ]; then
	echo "Read # of Correctable Errors on OCRAM"
	cat /sys/devices/system/edac/ocramedac/ocramedac0/ce_count
	cat /sys/devices/system/edac/ocramedac/ocramedac0/ce_count > ocram_cecount_orig.txt
fi

# Now perform at least 1 bit error on each.
echo; echo;
if [ -e /sys/devices/system/edac/mc/mc0/ce_count ]; then
	echo "Inject a correctable error into SDRAM"
	echo 1 > /sys/kernel/debug/edac/mc0/inject_ctrl
	sleep 1;
fi
if [ -e /sys/devices/system/edac/l2edac/l2edac0/ce_count ]; then
	echo "Inject a correctable error into L2 cache"
	echo 1 > /sys/devices/system/edac/l2edac/altr_l2_trigger
	echo 1 > /sys/devices/system/edac/l2edac/altr_l2_trigger
	sleep 1;
fi
if [ -e /sys/devices/system/edac/ocramedac/ocramedac0/ce_count ]; then
	echo "Inject a correctable error into OCRAM"
	echo 1 > /sys/devices/system/edac/ocramedac/altr_ocram_trigger
	sleep 1;
fi

# Repeat reads.
echo; echo
if [ -e /sys/devices/system/edac/mc/mc0/ce_count ]; then
	echo "Read # of Correctable Errors on SDRAM Mem Controller"
	cat /sys/devices/system/edac/mc/mc0/ce_count
	cat /sys/devices/system/edac/mc/mc0/ce_count > sdram_cecount_new.txt
fi
if [ -e /sys/devices/system/edac/l2edac/l2edac0/ce_count ]; then
	echo "Read # of Correctable Errors on L2 Cache"
	cat /sys/devices/system/edac/l2edac/l2edac0/ce_count
	cat /sys/devices/system/edac/l2edac/l2edac0/ce_count > l2_cecount_new.txt
fi
if [ -e /sys/devices/system/edac/ocramedac/ocramedac0/ce_count ]; then
	echo "Read # of Correctable Errors on OCRAM"
	cat /sys/devices/system/edac/ocramedac/ocramedac0/ce_count
	cat /sys/devices/system/edac/ocramedac/ocramedac0/ce_count > ocram_cecount_new.txt
fi

if test ! -e sdram_cecount_new.txt ; then
	echo "SDRAM ECC did not work - check to make sure it is enabled"
        status_fail=1
fi
if test ! -e l2_cecount_new.txt ; then
	echo "L2 ECC did not work - check to make sure it is enabled"
        status_fail=1
fi
if test ! -e ocram_cecount_new.txt ; then
	echo "OCRAM ECC did not work - check to make sure it is enabled"
        status_fail=1
fi

if [ "$status_fail" != '1' ]; then
   echo "Compare the DDR initial & ecc triggered files"
   CMD="diff sdram_cecount_orig.txt sdram_cecount_new.txt"
   echo "$CMD"
   $CMD
   ret=$?

   if [ "$ret" == '0' ]; then
        echo "FAIL - return code is $ret"
        status_fail=1
   fi

   echo "Compare the l2 initial & ecc triggered files"
   CMD1="diff l2_cecount_orig.txt l2_cecount_new.txt"
   echo "$CMD1"
   $CMD1
   ret1=$?

   if [ "$ret1" == '0' ]; then
        echo "FAIL - return code is $ret1"
        status_fail=1
   fi
   
   echo "Compare the OCRAM initial & ecc triggered files"
   CMD2="diff ocram_cecount_orig.txt ocram_cecount_new.txt"
   echo "$CMD2"
   $CMD2
   ret2=$?

   if [ "$ret2" == '0' ]; then
        echo "FAIL - return code is $ret2"
        status_fail=1
   fi
fi

# Cleanup
if [ -e sdram_cecount_orig.txt ]; then
	rm sdram_cecount_orig.txt
fi
if [ -e sdram_cecount_new.txt ]; then
	rm sdram_cecount_new.txt
fi
if [ -e l2_cecount_orig.txt ]; then
	rm l2_cecount_orig.txt
fi
if [ -e l2_cecount_new.txt ]; then
	rm l2_cecount_new.txt
fi
if [ -e ocram_cecount_orig.txt ]; then
	rm ocram_cecount_orig.txt
fi
if [ -e ocram_cecount_new.txt ]; then
	rm ocram_cecount_new.txt
fi

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail

