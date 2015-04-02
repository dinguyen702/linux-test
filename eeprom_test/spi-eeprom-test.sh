#!/bin/bash

# internals
SELF=$(basename $0)
SELFDIR=$(dirname $0)
DEVTREE_MODEL=/proc/device-tree/model

# library
source ${SELFDIR}/libeeprom.sh

function get_eeprom_size() {

    if egrep -q '(Cyclone V|Arria V) SoC Development Kit' ${DEVTREE_MODEL} || \
       egrep -q 'Altera SOCFPGA Arria 10' ${DEVTREE_MODEL} ; then
        echo 8192 
    fi

    return 0
}

function get_eeprom_sysfs_path_data() {

    if egrep -q '(Cyclone V|Arria V) SoC Development Kit' ${DEVTREE_MODEL} || \
       egrep -q 'Altera SOCFPGA Arria 10' ${DEVTREE_MODEL} ; then
        echo "/sys/class/spi_master/spi0/spi0.0/eeprom"
    fi

    return 0
}

# the path to the sys entry is machine specific

echo "kernel version : $(uname -a)"
EEPROM_DATA=$(get_eeprom_sysfs_path_data)
EEPROM_SIZE=$(get_eeprom_size)

for foo in ${EEPROM_DATA}  ; do 
    if [ ! -f "${foo}" ]; then
	echo "FAIL - sysfs path does not exist: ${foo}"
	exit 1
    fi
done

do_test_eeprom ${EEPROM_DATA} ${EEPROM_SIZE}
if [ $? -ne 0 ] ; then
    echo "${SELF}: test failed!"
    exit 1
fi

echo "${SELF}: test pass"

