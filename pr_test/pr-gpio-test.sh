#!/bin/bash
#
# This test assumes:
#  * Modified gsrd device tree, where the fpga leds are removed
#  * fit_v1.rbf and fit_v2.rbf which add an and or or gate between
#    some fpga gpio lines
#

verbose=0

get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    cat /proc/device-tree/model | cut -d ' ' -f 3-4 | tr -d ' '
}

write_fpga_image()
{
    if [ "$verbose" == 1 ]; then
	echo "Writing fpga image : $1"
    fi
    cat $1 > /dev/fpga0
    echo
}

set_gpios()
{
    gpio_config=$1
    for gpio in 252 253; do
	let val=$(( $gpio_config & 1 ))
	echo $val > /sys/class/gpio/gpio${gpio}/value
    done
}

set_gate_input_and_check_output()
{
    echo $1 > /sys/class/gpio/gpio252/value
    echo $2 > /sys/class/gpio/gpio253/value

    local val=$(cat /sys/class/gpio/gpio255/value)

    case $3 in
	'and' ) expected="$(( $1 & $2 ))" ;;
	'or' )  expected="$(( $1 | $2 ))" ;;
	* ) echo "coding error"; exit ;;
    esac

    if [ "$val" != "$expected" ]; then
	if [ "$verbose" == 1 ]; then
	    echo "$1 $3 $2 = $val FAIL"
	fi
	return 1
    fi

    if [ "$verbose" == 1 ]; then
	echo "$1 $3 $2 = $val PASS"
    fi

    return 0
}

# find out whether the gate is and or or
verify_gate()
{
    local failure=0

    if [ "$verbose" == 1 ]; then
	echo "Verifying $1 gate function"
    fi

    set_gate_input_and_check_output 0 0 $1
    if [ $? != 0 ]; then
	failure=1
    fi	

    set_gate_input_and_check_output 0 1 $1
    if [ $? != 0 ]; then
	failure=1
    fi	

    set_gate_input_and_check_output 1 0 $1
    if [ $? != 0 ]; then
	failure=1
    fi	

    set_gate_input_and_check_output 1 1 $1
    if [ $? != 0 ]; then
	failure=1
    fi	

    return $failure
}

usage()
{
    cat <<EOF
Usage: $(basename $0) [-v]

-v = verbose
EOF
}

#==================================================================

while [ -n "$1" ]; do
    case $1 in
	-v ) verbose=1 ;;
	* ) usage; exit ;;
    esac
    shift
done

case "$(get_devkit_type)" in
    Arria10 ) ;;
    * ) echo "ERROR - PR not supported."; return 1 ;;
esac

# export all the LED gpios as gpios.  Make # 0 and 1 be outputs.
for gpio in 252 253 254 255; do
    if [ ! -d /sys/class/gpio/gpio${gpio} ]; then
        echo $gpio > /sys/class/gpio/export
    fi
done
for gpio in 252 253; do
    echo out > /sys/class/gpio/gpio${gpio}/direction
done
for gpio in 254 255; do
    echo in > /sys/class/gpio/gpio${gpio}/direction
done

for gpio in 252 253 254 255; do
    if [ ! -d /sys/class/gpio/gpio${gpio} ]; then
	echo "ERROR: could not export gpio $gpio"
	echo "*** probably you need to remove fpga leds from device tree"
	exit
    fi
done
for gpio in 252 253; do
    direction="$(cat /sys/class/gpio/gpio${gpio}/direction)"
    if [ "$direction" != 'out' ]; then
	echo "ERROR: gpio $gpio direction is not out"
	exit
    fi
done
for gpio in 254 255; do
    direction="$(cat /sys/class/gpio/gpio${gpio}/direction)"
    if [ "$direction" != 'in' ]; then
	echo "ERROR: gpio $gpio direction is not in"
	exit
    fi
done

for foo in fit_pr_v1.rbf fit_pr_v2.rbf ; do
    if [ ! -f "$foo" ]; then
	echo "Could not find rbf image file : $foo"
	exit
    fi
done

let count=0
let fail_count=0
while true ; do
    echo "PR count : $count"
    echo "Failures : $fail_count"

    write_fpga_image fit_pr_v1.rbf
    verify_gate 'and'
    if [ $? != 0 ]; then
	let fail_count=fail_count+1
    fi	
    let count=count+1

    write_fpga_image fit_pr_v2.rbf
    verify_gate 'or'
    if [ $? != 0 ]; then
	let fail_count=fail_count+1
    fi	

    let count=count+1
    clear   
done
