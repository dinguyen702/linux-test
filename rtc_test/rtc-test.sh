#!/bin/sh

usage()
{
    cat <<EOF
$(basename $0) [-d rtc dev]

Tests the i2c rtc

 -d = rtc device name.  Defaults to $RTC_DEV

EOF
}

path_test()
{
    path=$1
    if [ -e "$path" ]; then
	echo "path exists: $path"
    else
	echo "FAIL - path does not exist: $path"
	status_fail=1
    fi
}

sysfs_test()
{
    attr=$1
    shift
    sysfs_value="$(cat $SYSFS/$attr)"
    echo "$SYSFS/$attr == $sysfs_value"
    if [ "$@" == 'ANYTHING' ]; then
	return
    fi
    if [ "$sysfs_value" != "$@" ]; then
	echo "ERROR $SYSFS/$attr == $sysfs_value ; expected $@"
	status_fail=1
    fi
}

hwclock_time()
{
    hwclock | cut -c1-24
}

date_time()
{
    date +'%a %b %_d %T %Y'
}

#===========================================================
echo "rtc test"
echo

RTC_DEV=rtc0
status_fail=0

while [ -n "$1" ]; do
    case $1 in
	-d ) RTC_DEV=$2 ; shift ;;
	-h|--help ) usage ; exit 1 ;;
    esac
    shift
done
DEVNODE=/dev/$RTC_DEV

if [ -z "$DEVNODE" ] || [ ! -e "$DEVNODE" ]; then
    echo "Error cannot find devnode $DEVNODE"
    exit 1
fi

SYSFS=/sys/class/rtc/$RTC_DEV
PROC=/proc/driver/rtc

path_test $SYSFS
path_test $SYSFS/time
path_test $SYSFS/date
path_test $PROC

# Angstrom issue:
# Must set system clock to something other than 1970:
date 010112002000

hw_tm="$(hwclock_time)"
sys_tm="$(date_time)"
echo
echo "rtc time    : $hw_tm"
echo "system time : $sys_tm"

echo
echo "Setting hwclock from system clock and reading again"
hwclock --systohc
hw_tm="$(hwclock_time)"
sys_tm="$(date_time)"
echo "rtc time    : $hw_tm"
echo "system time : $sys_tm"

for tries in 1 2 3 4; do
    hw_tm="$(hwclock_time)"
    sys_tm="$(date_time)"
    if [ "$hw_tm" == "$sys_tm" ]; then
	break
    fi
    echo "rtc time    : $hw_tm"
    echo "system time : $sys_tm"
    echo "FAIL could not set hwclock from system time"
    sleep 1
done

sysfs_test date "$(date +'%Y-%m-%d')"
sysfs_test time "$(date +'%T')"
sysfs_test name ds1339
sysfs_test hctosys ANYTHING
sysfs_test max_user_freq ANYTHING
sysfs_test since_epoch ANYTHING

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
