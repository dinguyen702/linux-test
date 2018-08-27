#!/bin/bash

# TODO: Add the MODULE_DIR to the shared library.
MODULE_DIR="/lib/modules/$(uname -r)/kernel/drivers/mtd"
CHECK_PATH="${MODULE_DIR}/spi-nor/"
declare -a DEV_PARTITION=0

# TODO: Put this in a shared library function. Currently used in spi_test & ecc_test.
function get_devkit_type()
{
	# Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
	# Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
	# Altera SOCFPGA Arria 10 ==> Arria10
	# SoCFPGA Stratix 10 SoCDK
	cat /proc/device-tree/model | sed 's/Altera //' | cut -d ' ' -f 2-3 | tr -d ' '
}

SOC="$(get_devkit_type)"
case ${SOC} in
	ArriaV|CycloneV) DEV_PARTITION=0 ;;
	# Arria10 has the boot code in partition0 so don't erase it.
	Arria10) DEV_PARTITION=1 ;;
	Stratix10) DEV_PARTITION=1 ;;
	*) echo "Unsupported SoC (${SOC})"; exit 1 ;;
esac

echo "Check for installed modules"

# Check to see if the module is already installed and if the kernel module
# is available. Install it if not installed already.
lsmod | grep -q 'spi_nor'
INST_RET_CODE=$?
echo "Retcode is ${INST_RET_CODE}"
if [ ${INST_RET_CODE} -ne 0  -a -e "${CHECK_PATH}/spi-nor.ko" ] ; then
	echo "install spi-nor module"
	if ! insmod "${MODULE_DIR}/spi-nor/spi-nor.ko"; then
		exit
	fi
else
	echo "The spi-nor module is already installed."
fi

# Check to see if the module is already installed and if the kernel module
# is available. Install it if not installed already.
lsmod | grep -q 'cadence_quadspi'
INST_RET_CODE=$?
echo "Retcode is ${INST_RET_CODE}"
if [ ${INST_RET_CODE} -ne 0 -a -e "${CHECK_PATH}/cadence-quadspi.ko" ] ; then
	echo "Install cadence_quadspi module"
	if ! insmod "${MODULE_DIR}/spi-nor/cadence-quadspi.ko" ; then
		exit
	fi
else
	echo "The cadence_quadspi module is already installed."
fi

echo "Operating on partition ${DEV_PARTITION} for ${SOC}"
MTD_DEV="mtd${DEV_PARTITION}"

flash_erase "/dev/${MTD_DEV}" 0 0

filename=qspi-data-file
filesize=$(ls -l $filename |awk -F" " '{ print $5 }')

echo filesize is $filesize

flashcp $filename "/dev/${MTD_DEV}"
rm qspi-data-out
mtd_debug read "/dev/${MTD_DEV}" 0 $filesize qspi-data-out

if ! diff -q $filename qspi-data-out; then
echo FAIL
status=1
else
echo PASS
status=0
fi
exit $status
