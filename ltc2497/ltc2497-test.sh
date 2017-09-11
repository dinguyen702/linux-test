#!/bin/sh

exit_fail()
{
    echo $@
    echo "FAIL"
    exit 1
}

print_voltage()
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

#=================================================================

status_fail=0

i2c_path=/sys/devices/platform/soc/ffc02900.i2c/i2c-0
ltc_addr=0-0014
ltc_path=${i2c_path}/${ltc_addr}/iio:device0

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

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
