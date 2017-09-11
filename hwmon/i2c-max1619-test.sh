#!/bin/sh

status_fail=0
hwmon0=/sys/devices/platform/soc/ffc02900.i2c/i2c-0/0-004c/hwmon/hwmon0

if [ ! -d "${hwmon0}" ]; then
    echo "Can't find ${hwmon0}"
    exit 1
fi

cd $hwmon0

pwd
ls
echo

for temp in temp1_input temp2_input; do
    printf "%-18s : %s\n" "$temp" "$(cat $temp)"
done
echo

for temp in temp2_max temp2_min temp2_crit temp2_crit_hyst; do
    printf "%-18s : %s\n" "$temp" "$(cat $temp)"
done

for temp in temp2_max_alarm temp2_min_alarm temp2_crit_alarm temp2_fault; do
    printf "%-18s : %s\n" "$temp" "$(cat $temp)"
done

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail

