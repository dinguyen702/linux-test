#!/bin/bash -x

# internals
SELF=$(basename $0)
SELFDIR=$(dirname $0)
DEVTREE_MODEL=/proc/device-tree/model

# library
source ${SELFDIR}/libeeprom.sh

function get_eeprom_size() {

    if egrep -q '(Cyclone V|Arria V) SoC Development Kit' ${DEVTREE_MODEL}  ; then
        echo 4096
    fi

    return 0
}

function get_eeprom_sysfs_path_name() {

    if egrep -q '(Cyclone V|Arria V) SoC Development Kit' ${DEVTREE_MODEL}  ; then
        echo "/sys/class/i2c-adapter/i2c-0/0-0051/name"
    fi

    return 0
}

function get_eeprom_sysfs_path_data() {

    if egrep -q '(Cyclone V|Arria V) SoC Development Kit' ${DEVTREE_MODEL}  ; then
        echo "/sys/class/i2c-adapter/i2c-0/0-0051/eeprom"
    fi

    return 0
}

# the path to the sys entry is machine specific

echo "kernel version : $(uname -a)"
EEPROM_NAME=$(get_eeprom_sysfs_path_name)
EEPROM_DATA=$(get_eeprom_sysfs_path_data)
EEPROM_SIZE=$(get_eeprom_size)

for foo in ${EEPROM_NAME} \
           ${EEPROM_DATA}  ; do
    if [ ! -f "${foo}" ]; then
	echo "FAIL - sysfs path does not exist: ${foo}"
	exit 1
    fi
done

# cab't move to general test, because not all EEPROM drivers show their name
echo "Reading eeprom name : cat ${EEPROM_NAME}"
cat ${EEPROM_NAME}
if [ "$?" != 0 ]; then
    echo "FAIL - during reading name."
    exit 1
fi

do_test_eeprom ${EEPROM_DATA} ${EEPROM_SIZE}
if [ $? -ne 0 ] ; then
    echo "${SELF}: test failed!"
    exit 1
fi

echo "${SELF}: test pass"

