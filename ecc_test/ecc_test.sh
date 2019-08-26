#!/bin/bash

status_fail=0

ECC_STATUS_PATH_TOP=/sys/devices/system/edac
SELF="$(basename $0)"
DIRSELF="$(dirname $0)"

# ------------ Main Memory ECCs ------------------------------
declare -a MEMORY_ECC_PERIPHERALS=()

declare -ar CA5_MEMORY_ECC_PERIPHS=("ddr" "l2" "ocram")
declare -ar A10_MEMORY_ECC_PERIPHS=("ddr" "l2" "ocram")
declare -ar S10_MEMORY_ECC_PERIPHS=("ddr" "ocram")

# ------------ FIFO ECCs ------------------------------
declare -a FIFO_ECC_PERIPHERALS=()

declare -ar A10_FIFO_ECC_PERIPHS=("usb0" "usb1" "qspi" "nand" "dma" "emac0-rx" \
				 "emac0-tx" "emac1-rx" "emac1-tx" "emac2-rx" \
				 "emac2-tx" "sdmmca" "sdmmcb")

declare -ar S10_FIFO_ECC_PERIPHS=("usb0" "usb1" "qspi" "nand" "dma" "emac0-rx" \
				 "emac0-tx" "emac1-rx" "emac1-tx" "emac2-rx" \
				 "emac2-tx" "sdmmca" "sdmmcb")

declare -a ecc_err_accounting=()

# TODO: Put this in a shared library function. Currently used in spi_test.
function get_devkit_type()
{
	# Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
	# Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
	# Altera SOCFPGA Arria 10 ==> Arria10
	# SoCFPGA Stratix 10 SoCDK ==> Stratix10
	cat /proc/device-tree/model | sed 's/Altera //' | cut -d ' ' -f 2-3 | tr -d ' '
}

# See if an element is contained in the array (0 if yes(SUCCESS), 1 if no)
# $1 = element to search for (needle)
# $2 = array to search (haystack)
# works with empty arrays.
function contains_element()
{
	local needle="$1"; shift;
	declare -a haystack=("$@")

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
	local skip_ecc="$2"
	local ecc_dir="${ecc_name}-ecc"
	# DDR is special and has a memory controller designation.
	if [ "${ecc_name}" == "ddr" ]; then
		ecc_dir="mc"
	fi
	local err_status_path_root="${ECC_STATUS_PATH_TOP}/${ecc_dir}"
	local ecc_instance="${3:-0}"
	local err_status_path="${err_status_path_root}/${ecc_dir}${ecc_instance}"
	# DDR is special and has a memory controller designation with instance.
	if [ "${ecc_name}" == "ddr" ]; then
		ecc_dir="mc0"
	fi
	local err_inject_path="/sys/kernel/debug/edac/${ecc_dir}/altr_trigger"

	# Check allowed list of peripherals. Quit if not valid
	if ( contains_element "{ecc_name}" "${MEMORY_ECC_PERIPHERALS[@]}" \
				"${FIFO_ECC_PERIPHERALS[@]}" ); then
		echo "ERROR: ${FUNCNAME} => invalid ECC ${ecc_name}"
		status_fail=1
		return
	fi
	echo "ECC Peripheral is $1"
	#echo "Status path is ${err_status_path}"

	if [ -d ${err_status_path_root} ]; then
		local compare_result="FAIL"
		echo -e "${FUNCNAME} => ${ecc_name} enabled - testing."
		local start_cerrs="$(cat ${err_status_path}/ce_count)"
		local start_uerrs="$(cat ${err_status_path}/ue_count)"
		sleep 1

		echo 'C' > ${err_inject_path}
		if [ ${skip_ecc} -eq 0 ]; then
			echo 'U' > ${err_inject_path}
		fi

		sleep 1
		local end_cerrs="$(cat ${err_status_path}/ce_count)"
		local end_uerrs="$(cat ${err_status_path}/ue_count)"

		#echo; echo "${ecc_name^^} ECC TEST RESULT:"
		# OCRAM, SDRAM, and L2 cache will panic on Uncorrectable errors.
		if [ ${skip_ecc} -eq 0 ]; then
			if [ ${start_cerrs} -ne ${end_cerrs} ] &&
			   [ ${start_uerrs} -ne ${end_uerrs} ]; then
				compare_result="PASS"
			else
				status_fail=1
			fi
		else
			if [ ${start_cerrs} -ne ${end_cerrs} ]; then
				compare_result="PASS"
			else
				status_fail=1
			fi
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

#------------------- Main Memory Tests ------------------------------
case ${SOC} in
	ArriaV|CycloneV) MEMORY_ECC_PERIPHERALS=( "${CA5_MEMORY_ECC_PERIPHS[@]}" ) ;;
	Arria10) MEMORY_ECC_PERIPHERALS=( "${A10_MEMORY_ECC_PERIPHS[@]}" ) ;;
	Stratix10) MEMORY_ECC_PERIPHERALS=( "${S10_MEMORY_ECC_PERIPHS[@]}" ) ;;
	*) echo "Unsupported SoC (${SOC})"; exit 1 ;;
esac

# Cycle through all the different Memories.
for ecc_arg in "${MEMORY_ECC_PERIPHERALS[@]}"
do
	ecc_test::inject_and_check_errors ${ecc_arg} 1
	echo "---------------------------------------------------------"
done
echo
echo "Running the Peripheral FIFO ECC Tests"

#----------------- Peripheral FIFO Tests ----------------------------
case ${SOC} in
	ArriaV|CycloneV) true ;;
	# Only Arria10 supports FIFO ECCs right now.
	Arria10) FIFO_ECC_PERIPHERALS=( "${A10_FIFO_ECC_PERIPHS[@]}" ) ;;
	Stratix10) FIFO_ECC_PERIPHERALS=( "${S10_FIFO_ECC_PERIPHS[@]}" ) ;;
	*) echo "Unsupported SoC (${SOC})"; exit 1 ;;
esac

# Cycle through all the different FIFO peripherals.
for ecc_arg in "${FIFO_ECC_PERIPHERALS[@]}"
do
	case ${SOC} in
		Arria10) ecc_test::inject_and_check_errors ${ecc_arg} 0 ;;
		Stratix10) ecc_test::inject_and_check_errors ${ecc_arg} 1 ;;
	esac
	echo "---------------------------------------------------------"
done
echo
# Short delay to allow any deferred UE errors to print.
sleep 2

#----------------- Print the ECC results ----------------------------
# Print the ECC summary results
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

echo
if [ "$status_fail" == 0 ]; then
	echo "TEST PASSED"
else
	echo "TEST FAILED due to failures already listed above"
fi

exit $status_fail
