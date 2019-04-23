#!/bin/sh

function get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    # Altera SOCFPGA Arria 10 ==> Arria10
    # SoCFPGA Stratix 10 SoCDK ==> Stratix10
    cat /proc/device-tree/model | sed 's/Altera //' | cut -d ' ' -f 2-3 | tr -d ' '
}

function exit_fail()
{
    echo $@
    echo "FAIL"
    exit 1
}

function print_voltage()
{
    if [ ! -e "$1" ]; then
	echo "not found: $1"
	status_fail=1
    else
	voltage=$(cat ${1})
	if [ $? -ne 0 ]; then
	    echo "Error reading voltage ($1)"
	    status_fail=1
	else
	    printf "%s %s\n" "${1}" "$voltage"
	fi
    fi
}

function run_ltc_test()
{
    i2c_path=$1
    ltc_addr=$2
    ltc_device_num=$3
    
    ltc_path=${i2c_path}/${ltc_addr}/iio:device${ltc_device_num}

    if [ ! -d "${ltc_path}" ]; then
	exit_fail "Not found: ${ltc_path}"
    fi

    cd ${ltc_path} || exit_fail "could not cd to ${ltc_path}"

    name="$(cat name)"
    if [ "${name}" != 'ltc2497' ]; then
	exit_fail "name ($name) is not ltc2497"
    else
	echo "Name = $name"
    fi
    echo
    echo "Device is at:"
    echo " $ltc_path"
    echo
    ls
    echo

    for v_in in in_voltage_scale in_voltage-voltage_scale; do
    print_voltage ${v_in}
    done
    echo
    for num in $(seq 0 15); do
	print_voltage "in_voltage${num}_raw"
    done
    echo
    for num1 in $(seq 0 2 15); do
	let num2=num1+1
	v_in1="in_voltage${num1}-voltage${num2}_raw"
	v_in2="in_voltage${num2}-voltage${num1}_raw"
	print_voltage ${v_in1}
	print_voltage ${v_in2}
    done
}

#=================================================================

status_fail=0
ltc_devices=

SOC="$(get_devkit_type)"
case ${SOC} in
    Arria10)
	i2c_path=/sys/devices/platform/soc/ffc02300.i2c/i2c-0
	run_ltc_test $i2c_path 0-0014 0
	run_ltc_test $i2c_path 0-0016 1
	;;
    Stratix10)
	i2c_path=/sys/devices/platform/soc/ffc02900.i2c/i2c-0
	run_ltc_test $i2c_path 0-0014 0
	;;
    *)
	echo "Unsupported SoC (${SOC})"; exit 1 ;;
esac

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
