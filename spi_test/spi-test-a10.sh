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

# Find the correct hwmon because Angstrom find isn't recursive.
get_hwmon_path()
{
	testpath=$1
	echo "Testpath is ${testpath}"
	for foo in ${testpath}/hwmon*
	do
	    test=$(cat ${foo}/device/name)
	    if [ "$test" == 'a10sycon' ]; then
	    	path_found=1
	    	hwmon_path=${foo}
		break
	    fi
	done
}

usage()
{
    cat <<EOF
In the case of Arria10:
We can read the version number from the MAX5 and toggle the LEDs and
verify the results.

Usage: $(basename $0) [-h]

i.e.:
 $  $(basename $0)
  Execute the test

 $  $(basename $0) -h
  Print this message.

EOF
}

echo
# Is this a valid board to run spi-loopback test on?
case "$(get_devkit_type)" in
    ArriaV )  echo "Arria5 DevKit - No MAX5. Exiting." ; exit 0 ;;
    CycloneV ) echo "Cyclone5 DevKit - No MAX5. Exiting." ; exit 0 ;;
    Arria10 )  echo "Arria10 DevKit - Executing MAX5 Test." ;;
    * ) echo "Unable to identify board. Exiting." ; exit 0 ;;
esac

while [ -n "$1" ]; do
    case $1 in
	-h|--help ) usage ; exit ;;
	* ) echo "unknown parameter: $1" ; echo ; usage ; exit ;;
    esac
    shift
done

status_fail=0
path_found=0
	
# Use the hwmon to read the version number.
echo
hwmon_path="/sys/class/hwmon"
if test ! -d ${hwmon_path} ; then
	echo "ERROR: The MAX5 hwmon can't be found. Exiting."
	status_fail=1
else
	get_hwmon_path ${hwmon_path}

	if [ "$path_found" == 1 ]; then
		hwmon_path="${hwmon_path}/device"
		echo "A10 System Control hwmon path is ${hwmon_path}"

		version=$(cat ${hwmon_path}/max5_version)
		echo "Arria10 MAX5 version is ${version}"
		if [ "$version" != '0xA' ]; then 
			echo "Error: The MAX5 version is incorrect."
			status_fail=1
		fi
		# Check the current LED state.
		led_state=$(cat ${hwmon_path}/max5_led)
		echo "LED state is ${led_state}"
		if [ "$led_state" != '0x0' ]; then 
			echo "ERROR: The MAX5 LED state should be 0x0."
			status_fail=1
		fi

		# Check the LED path.
		led_path="/sys/class/leds/a10sycon_led0"
		if test ! -d ${led_path} ; then
			echo "ERROR: The MAX5 LED path can't be found."
			status_fail=1
		else		
			# Toggle the LED.	
			echo 0 > ${led_path}/brightness
			
			# Check the current LED state.
			led_state=$(cat ${hwmon_path}/max5_led)
			echo "LED state is ${led_state}"
			if [ "$led_state" != '0x10' ]; then 
				echo "ERROR: The MAX5 LED state should be 0x10."
				status_fail=1
			fi
			
			# Revert the LED.
			echo 1 > ${led_path}/brightness
		fi
	else
		echo "ERROR: Couldn't find hwmon path"
		status_fail=1
	fi
	echo
fi

if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail


