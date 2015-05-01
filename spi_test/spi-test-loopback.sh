#!/bin/bash

get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    # Altera SOCFPGA Arria 10 ==> Arria10
    cat /proc/device-tree/model | cut -d ' ' -f 3-4 | tr -d ' '
}

get_kernel_version()
{
   uname -r | cut -c -4 | cut -c 3-5
}

usage()
{
    cat <<EOF
Test will generate a random binary file then call "spi-test-loopback"
to send this data out on the SPI bus. To use this test, first 
configure the CycloneV board to loopback SPI output. 
   
   CycloneV:
   Configure the board by placing a jumper across the 5 & 7 pins of 
   J32 which shorts MISO to MOSI.

This script calls "spi-test-loopback" with the following command:
   spi-test-loopback -D ${SPI_DEVNODE} -w spi_random_inputfile.bin -r spi_loopback_read.bin

Usage: $(basename $0) [-h][-c <iterations(0=continuous)>][-D <device>]

i.e.:
 $  $(basename $0)
  Default is run continuously - similar to -c 0

 $  $(basename $0) -c 1000
  Write-read-compare 1000 times. Use default => ${SPI_DEVNODE}

 $  $(basename $0) -D spidev1.0
  Run this test on /dev/spidev1.0.  Note that this device currently 
     is not pinned out to anything on the CycloneV board!

$  $(basename $0) -h
  Print this message.

EOF
}

# Is this a valid board to run spi-loopback test on?
case "$(get_devkit_type)" in
    ArriaV )  echo "Arria5 DevKit - No SPI loopback. Exiting." ; exit 0 ;;
    CycloneV ) echo "Cyclone5 DevKit Found. Executing Test." ;;
    Arria10 )  echo "Arria10 DevKit - No SPI loopback. Exiting." ; exit 0 ;;
    * ) echo "Unable to identify board. Exiting." ; exit 0 ;;
esac

SPIDEVS="$(find /dev/ -maxdepth 1 -type c | egrep -e "spidev[0-9]")"
NUMSPIDEVS=$(echo ${SPIDEVS} | wc -w)

echo "Discovered SPIDEVS are ${SPIDEVS}"
echo "Num SPIDEVS are ${NUMSPIDEVS}"
if [ ${NUMSPIDEVS} -eq 0 ]; then
    echo "Error: Need at least 1 SPIDEV for test."
    exit 1
fi

if [ ${NUMSPIDEVS} -gt 1 ]; then
    echo "Error: More than 1 SPIDEV available."
    exit 1
fi
echo

SPI_DEVNODE=${SPIDEVS}
ITERATIONS=0

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
    echo "Perform this test $ITERATIONS times on ${SPI_DEVNODE}."
    echo
fi

#=============================================================
# Set to an insanely high iteration number if 0
if [ "$ITERATIONS" -eq 0 ]
then ITERATIONS=999999999
fi

COUNT=$ITERATIONS
FAIL_COUNT=0
status_fail=0

for (( a=1; a <= $COUNT; a++ ))
do
	# Generate a random number in the range of 0 to 1024.
	NUM_BYTES=$(( $RANDOM % 1024 ))
	echo
	echo -n "Number of Bytes = $NUM_BYTES"
	echo

	#Generate random data in the file
	dd if=/dev/urandom of=spi_seed_file.bin bs=$NUM_BYTES count=1
	# Perform the SPI loopback test.
	./spi-test-loopback -D ${SPI_DEVNODE} -w spi_seed_file.bin -r spi_read_result.bin

	
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
		status_fail=1
	fi
done
let "a--"
echo
echo "There were $FAIL_COUNT failures out of $a iterations"
echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
