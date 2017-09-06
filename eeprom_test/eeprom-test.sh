#!/bin/sh

SYSFS_PATH=/sys/class/i2c-adapter/i2c-0/0-0051

# Note that the 24LC32A EEPROM is 32K bits (4K bytes)
DATA_SIZE_KB=4

i2c_ee_write()
{
    dd if=$1 of=$SYSFS_PATH/eeprom bs=1024
    if [ "$?" != 0 ]; then
	echo "FAIL while writing EEPROM"
	exit 1
    fi
    echo
}

i2c_ee_read()
{
    if [ -z "$1" ]; then
	echo "need a file to write to"
	exit 1
    fi

    dd if=$SYSFS_PATH/eeprom of=$1 bs=1024 count=$DATA_SIZE_KB
    if [ "$?" != 0 ]; then
	echo
	echo "FAIL while reading EEPROM"
	exit 1
    fi
    echo
}

i2c_write_read_compare()
{
    if [ -z "$1" ]; then
	echo "nothing to write"
	exit 1
    fi

    if [ ! -f "$1" ]; then
	echo "no file to write"
	exit 1
    fi

    echo "Writing $1 to EEPROM..."
    i2c_ee_write $1

    if [ -f /tmp/data-read ]; then
	rm /tmp/data-read
    fi
    
    echo "Reading from EEPROM..."
    i2c_ee_read /tmp/data-read

    diff $1 /tmp/data-read
    if [ "$?" != 0 ]; then
	echo "FAIL - data read does not match data written."
	exit 1
    fi
    echo
}

#=======================================================================

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

echo "Read old data from EEPROM..."
i2c_ee_read /tmp/saved-data

echo "Creating random test data..."
dd if=/dev/urandom of=/tmp/test-pattern bs=1024 count=$DATA_SIZE_KB
ls -l /tmp/test-pattern
echo

i2c_write_read_compare /tmp/test-pattern
i2c_write_read_compare /tmp/saved-data

echo
echo "PASS"

