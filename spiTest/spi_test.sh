#!/bin/bash
#spi_test.sh

# this file was designed to run with Spidev_test.c to test the spi connection
# on the socfpga5xs1 characterization board.

#usage spi_test -D /dev/spidev1.0
# you need to make sure that you have compiled the spidev_test.c and that
# the spi device is plugged in.

if [ $# -eq 0 ]
then
	echo "usage example: ./spi_test /dev/spidev1.0\n"
	exit
else
	echo "device is $1"
fi

transmitArray=(
		0x01 0x02 0x03 0x04 0x05 0x06
		0x07 0x08 0x09 0x0A 0x0B 0x0C
		0x0D 0x0E 0x0F 0xFF 0xFE 0xFD
		0xFC 0xFB 0xFA 0xF9 0xF8 0xF7
		0xF6 0xF5 0xF4 0xF3 0xF2 0xF1
		0xF0)

	echo
	echo "spi test beginning.\n"
	echo "test device selection.\n"
	
	echo "make sure the device is plugged into the board.\n"
	echo "make sure to set the correct mode and speed in the spidev_test.c"
	echo " and recompile.\n"
	echo "transmit array: ${transmitArray[*]]}"
	# todo this part is untested because i didn't have a spi device attached
	# also need to recompile this for the arm processor.
	# ./spidev-test -D $1 >spiResults.txt
	
	grep "can't" spiResults.txt
	RESULTS=$?	
	if [ $RESULTS -eq 0 ];
	then
		echo "spi test FAILED."
	else
		echo checking results
		i=0
		for WORD in $(cat spiResults.txt)
		do
			if [ "$WORD" != "${transmitArray[i]}" ]
			then
				echo "spi read/write FAILED"
				exit
			fi
			i=$[$i+1]
   	done
		echo "spi test PASSED."		
	fi
	echo "there are the results"
	more spiResults.txt

