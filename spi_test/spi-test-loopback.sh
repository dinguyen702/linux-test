#!/bin/bash

SPI_DEVNODE=spidev0.0
ITERATIONS=0

usage()
{
    cat <<EOF
Test will generate a random binary file then call "spi-test-loopback"
to send this data out on the SPI bus. To use this test, first 
configure the CycloneV board to loopback SPI output. 
   
   Configure the board by placing a jumper across the 5 & 7 pins of 
   J32 which shorts MISO to MOSI.

This script calls "spi-test-loopback" with the following command:
   spi-test-loopback -D /dev/spidev0.0 -w spi_random_inputfile.bin -r spi_loopback_read.bin

Usage: $(basename $0) [-h][-c <iterations(0=continuous)>][-D <device>]

i.e.:
 $  $(basename $0)
  Default is run continuously - similar to -c 0

 $  $(basename $0) -c 1000
  Write-read-compare 1000 times. Use default => /dev/spidev0.0

 $  $(basename $0) -D spidev1.0
  Run this test on /dev/spidev1.0.  Note that this device currently 
     is not pinned out to anything on the CycloneV board!

EOF
}


while [ -n "$1" ]; do
    case $1 in
	-h|--help ) usage ; exit ;;
	-c ) ITERATIONS=$2 ; shift ;;
	-D ) SPI_DEVNODE=$2 ; shift ;;
	* ) echo "unknown parameter: $1" ; echo ; usage ; exit ;;
    esac
    shift
done

if [ -n "$ITERATIONS" ]; then
    echo "Perform this test $ITERATIONS times."
else
    echo "Test will pause for the user to hit the ENTER key between test cases."
    echo
fi

#=============================================================
# Set to an insanely high iteration number if 0
if [ "$ITERATIONS" -eq 0 ]
then ITERATIONS=999999999
fi

COUNT=$ITERATIONS
FAIL_COUNT=0

for (( a=1; a <= $COUNT; a++ ))
do
	# Generate a random number in the range of 0 to 1024.
	NUM_BYTES=$(( $RANDOM % 1024 ))
	echo -n "Number of Bytes = $NUM_BYTES"
	echo

	#Generate random data in the file
	dd if=/dev/urandom of=spi_seed_file.bin bs=$NUM_BYTES count=1
	# Perform the SPI loopback test.
	./spi-test-loopback -D /dev/$SPI_DEVNODE -w spi_seed_file.bin -r spi_read_result.bin

	
	#Compare the input and output filenames
	cmp spi_seed_file.bin spi_read_result.bin
	
	if [ $? -eq 0 ]
	then
		let "SUCCESS_COUNT++"
	else
		echo "!!!!Compare failed on iteration $a!!"
		echo "Number of Bytes sent was $NUM_BYTES."
		echo
		let "FAIL_COUNT++"
	fi
done
let "a--"
echo
echo "There were $FAIL_COUNT failures out of $a iterations"
echo
echo "Done!"
echo
