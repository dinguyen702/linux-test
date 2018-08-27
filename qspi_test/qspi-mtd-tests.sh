#!/bin/bash

MODULE_DIR="/lib/modules/$(uname -r)/kernel/drivers/mtd"
CHECK_PATH="${MODULE_DIR}/spi-nor/"
declare -a DEV_PARTITION=0
declare -x LOADED_MODULES=""

# TODO: Put this in a shared library function. Currently used in spi_test & ecc_test.
function get_devkit_type()
{
	# Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
	# Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
	# Altera SOCFPGA Arria 10 ==> Arria10
	# SoCFPGA Stratix 10 SoCDK
	cat /proc/device-tree/model | sed 's/Altera //' | cut -d ' ' -f 2-3 | tr -d ' '
}

# TODO: Put this in a shared library function. Currently used in qspi_test but maybe dma.
function cleanup_modules()
{
	loaded_modules="$@"
	echo "Unravel the installed modules."
	for module in ${loaded_modules}; do
		MODULE_NAME="${module//-/_}"
		echo "Removing ${MODULE_NAME}"
		if ! modprobe -r ${MODULE_NAME}; then
			echo "!! Unable to remove module[${MODULE_NAME}]."
		fi
	done
}

SOC="$(get_devkit_type)"
case ${SOC} in
	ArriaV|CycloneV) DEV_PARTITION=0 ;;
	# Arria10 has the boot code in partition0 so don't erase it.
	Arria10) DEV_PARTITION=1 ;;
	Stratix10) DEV_PARTITION=1 ;;
	*) echo "Unsupported SoC (${SOC})"; exit 1 ;;
esac

#Clear the log because we read the log at the end.
dmesg -c 2>&1 > /dev/null

echo "Check for installed modules"

for module in spi-nor cadence-quadspi ; do
	# Check to see if the module is already installed and if the kernel module
	# is available. Install it if not installed already.
	MODULE_NAME="${module/-/_}"
	lsmod | grep -q "${MODULE_NAME}"
	INST_RET_CODE=$?
	echo "Retcode is ${INST_RET_CODE}"
	if [ ${INST_RET_CODE} -ne 0  -a -e "${CHECK_PATH}/${module}.ko" ] ; then
		echo "install ${module} module"
		if ! insmod "${MODULE_DIR}/spi-nor/${module}.ko" ; then
			echo "Problem installing ${module}. Exiting..."
			cleanup_modules "${LOADED_MODULES}"
			exit -1
		fi
	else
		echo "The ${module} module is already installed."
	fi
	LOADED_MODULES="${module} ${LOADED_MODULES}"
done

echo "Using parition ${DEV_PARTITION} for ${SOC}"
echo
echo "Beginning Tests..."
echo

for module in mtd_speedtest mtd_readtest mtd_stresstest; do
	echo "Run Test: ${module}"
	if ! insmod "${MODULE_DIR}/tests/${module}.ko" "dev=${DEV_PARTITION}"
	then 
		echo "Problem running ${module}. Exiting..."
		cleanup_modules "${LOADED_MODULES}"
		exit -1
	fi
	LOADED_MODULES="${module} ${LOADED_MODULES}"
done

echo "Test Results"

dmesg

cleanup_modules "${LOADED_MODULES}"

echo "MTD Tests complete"

