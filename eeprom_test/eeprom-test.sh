#!/bin/bash

SYSFS_PATH=/sys/class/i2c-adapter/i2c-0/0-0051

# Note that the 24LC32A EEPROM is 32K bits (4K bytes)
DATA_SIZE_KB=4

echo "kernel version : $(uname -a)"

for foo in name eeprom ; do
    if [ ! -f "$SYSFS_PATH/$foo" ]; then
	echo "FAIL - sysfs path does not exist: $SYSFS_PATH/$foo"
	exit 1
    fi
done

rm -f /tmp/data 2>/dev/null
rm -f /tmp/data-read 2>/dev/null

echo "Reading eeprom name : cat $SYSFS_PATH/name"
cat $SYSFS_PATH/name
if [ "$?" != 0 ]; then
    echo "FAIL - during reading name."
    exit 1
fi

echo "Creating random test data..."
dd if=/dev/urandom of=/tmp/data bs=1024 count=$DATA_SIZE_KB
ls -l /tmp/data
echo
echo "Writing to EEPROM..."
dd if=/tmp/data of=$SYSFS_PATH/eeprom bs=1024
if [ "$?" != 0 ]; then
    echo "FAIL while writing EEPROM"
    exit 1
fi
echo
echo "Reading from EEPROM..."
dd if=$SYSFS_PATH/eeprom of=/tmp/data-read bs=1024 count=$DATA_SIZE_KB
if [ "$?" != 0 ]; then
    echo
    echo "FAIL while reading EEPROM"
    exit 1
fi

diff /tmp/data /tmp/data-read
if [ "$?" != 0 ]; then
    echo "FAIL - data read does not match data written."
    exit 1
fi
echo
echo "PASS"

