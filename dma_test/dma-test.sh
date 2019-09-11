#!/bin/bash

BASE_URL=$1

# TODO: Put this in a shared library function. Currently used in spi_test.
function get_devkit_type()
{
	# Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
	# Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
	# Altera SOCFPGA Arria 10 ==> Arria10
	# SoCFPGA Stratix 10 SoCDK ==> Stratix10
	cat /proc/device-tree/model | sed 's/Altera //' | cut -d ' ' -f 2-3 | tr -d ' '
}

SOC="$(get_devkit_type)"

DMA_CHANNEL_NUM=8
#------------------- Channel Selector ------------------------------
case ${SOC} in
	#C5 assigns 2 DMA channels to UART so can't be used.
	ArriaV|CycloneV) DMA_CHANNEL_NUM=6;;
	Arria10) DMA_CHANNEL_NUM=8;;
	Stratix10) DMA_CHANNEL_NUM=8;;
	*) echo "Unsupported SoC (${SOC})"; exit 1 ;;
esac

cwd=$(pwd)
cd /
rm modules.tar
wget $BASE_URL/modules.tar
tar xf modules.tar

dmesg -C
dmesg -n 3

echo "Insert PL330 Module"
modprobe pl330
echo "Insert dmatest Module"
modprobe dmatest

echo 10 >/sys/module/dmatest/parameters/iterations

# Specify use all the available channels
echo "" >/sys/module/dmatest/parameters/channel
sleep 1

echo Y >/sys/module/dmatest/parameters/run

sleep 5

dmesg

echo "-----------------------------------------------------------"

# success_count=`grep -c "dma0chan[0-7].*0 failures" /var/log/messages`
success_count=`dmesg|grep -c "dma0chan[0-7].*0 failures"`

cd $cwd

echo "Remove dmatest Module"
rmmod dmatest
echo "Remove PL330 Module"
rmmod pl330

echo Success count is $success_count
if [ $success_count = "${DMA_CHANNEL_NUM}" ]
then
echo "PASS"
status=0
else
echo "FAIL"
status=1
fi
exit $status
