#!/bin/bash

status_fail=0

ECC_STATUS_PATH_TOP=/sys/devices/system/edac
SELF="$(basename $0)"
DIRSELF="$(dirname $0)"

declare -a FIFO_ECC_PERIPHERALS=()

declare -ar A10_FIFO_ECC_PERIPHS=("usb0" "usb1" "qspi" "nand" "dma" "emac0-rx" \
				 "emac0-tx" "emac1-rx" "emac1-tx" "emac2-rx" \
				 "emac2-tx" "sdmmca" "sdmmcb")

declare -a ecc_err_accounting=()

# TODO: Put this in a shared library function. Currently used in spi_test.
function get_devkit_type()
{
	# Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
	# Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
	# Altera SOCFPGA Arria 10 ==> Arria10
	cat /proc/device-tree/model | cut -d ' ' -f 3-4 | tr -d ' '
}

# See if an element is contained in the array (0 if yes(SUCCESS), 1 if no)
# $1 = element to search for (needle)
# $2 = array to search (haystack)
# works with empty arrays.
function contains_element()
{
	local needle="$1"
	declare -a haystack=("${!2}")

	if [ "$( echo ${haystack[@]} | grep -w -o ${needle} | wc -l )" -gt "0" ]; then
		return 0
	fi
	return 1
}

# Inject an error and expect the error count to increment
# or in some cases, more than 1 error is injected.
# $1 = Specific ECC type (ie. usb0).
# $2 = Skip Uncorrectable error (1 to skip)
# $3 = Peripheral instance (ie usb0-ecc0 for USB0's FIFO ECC)
function ecc_test::inject_and_check_errors() {
	local ecc_name="$1"
	local ecc_dir="${ecc_name}-ecc"
	local err_status_path_root="${ECC_STATUS_PATH_TOP}/${ecc_dir}"
	local ecc_instance="${3:-0}"
	local err_status_path="${err_status_path_root}/${ecc_dir}${ecc_instance}"
	local err_inject_path="/sys/kernel/debug/edac/${ecc_dir}/altr_trigger"

	# Check allowed list of peripherals. Quit if not valid
	if ( contains_element "{ecc_name}" "${FIFO_ECC_PERIPHERALS[@]}" ); then
		echo "ERROR: ${FUNCNAME} => invalid ECC ${ecc_name}"
		status_fail=1
		return
	fi
	echo "Peripheral is $1"
	#echo "Status path is ${err_status_path}"

	if [ -d ${err_status_path_root} ]; then
		local compare_result="FAIL"
		echo -e "${FUNCNAME} => ${ecc_name} enabled - testing."
		local start_cerrs="$(cat ${err_status_path}/ce_count)"
		local start_uerrs="$(cat ${err_status_path}/ue_count)"
		sleep 1

		echo 'C' > ${err_inject_path}
		if [ $2 -eq 0 ]; then
			echo 'U' > ${err_inject_path}
		fi

		local end_cerrs="$(cat ${err_status_path}/ce_count)"
		local end_uerrs="$(cat ${err_status_path}/ue_count)"

		#echo; echo "${ecc_name^^} ECC TEST RESULT:"
		# OCRAM, SDRAM, and L2 cache will panic on Uncorrectable errors.
		if [ ${start_cerrs} -ne ${end_cerrs} ] &&
		   [ ${start_uerrs} -ne ${end_uerrs} ]; then
			compare_result="PASS"
		else
			status_fail=1
		fi
		# Accumulate the results for summarizing later
		ecc_err_accounting[${index}]=$1
		ecc_err_accounting[${index}+1]=${start_cerrs}
		ecc_err_accounting[${index}+2]=${start_uerrs}
		ecc_err_accounting[${index}+3]=${end_cerrs}
		ecc_err_accounting[${index}+4]=${end_uerrs}
		ecc_err_accounting[${index}+5]=${compare_result}
		index=$((index+6))
		echo
	else
		echo -e "${FUNCNAME} => ${ecc_name} not found/enabled - skipping test."
	fi
	sleep 1
}

echo "---------------------------------------------------------"
echo "   Running ${SELF}"
echo "---------------------------------------------------------"

SOC="$(get_devkit_type)"

case ${SOC} in
	ArriaV|CycloneV) true ;;
	# Only Arria10 supports FIFO ECCs right now.
	Arria10) FIFO_ECC_PERIPHERALS=( "${A10_FIFO_ECC_PERIPHS[@]}" ) ;;
	*) echo "Unsupported SoC (${SOC})"; exit 1 ;;
esac

# Cycle through all the different FIFO peripherals.
for ecc_arg in "${FIFO_ECC_PERIPHERALS[@]}"
do
	ecc_test::inject_and_check_errors ${ecc_arg} 0
	echo "---------------------------------------------------------"
done
echo
# Short delay to allow any deferred UE errors to print.
sleep 2

# Print the Peripheral ECC summary results
element_count=${#ecc_err_accounting[@]}
index=0
echo "ECC Test Summary (${SELF})"
echo "---------------------------------------------------------"
while [ "${index}" -lt "${element_count}" ]
do
	echo "ECC Type: ${ecc_err_accounting[${index}]}"
	echo "                start | end |"
	echo "  Correctable:      ${ecc_err_accounting[${index}+1]} |   ${ecc_err_accounting[${index}+3]} |"
	echo "  Uncorrectable:    ${ecc_err_accounting[${index}+2]} |   ${ecc_err_accounting[${index}+4]} |"
	echo "  ECC Results  : ${ecc_err_accounting[${index}+5]}"
	echo "---------------------------------------------------------"
	index=$((index+6))
done

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

