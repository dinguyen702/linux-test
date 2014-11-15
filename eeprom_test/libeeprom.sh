#!/bin/bash

TMP_DATA_FILE_W=/tmp/data-w
TMP_DATA_FILE_R=/tmp/data-r

function create_test_data() {

    local data_file="$1"
    local size_b="$2"
    
    dd if=/dev/urandom of=${data_file} bs=${size_b} count=1 >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME}: error: failed to create data file"
        return 1
    fi

    return 0
}

function list_test_byte_amounts() {

    local mem_size_b="$1"
    local list=""

    while [ ${mem_size_b} -gt 0 ] ; do
        list=$(echo ${mem_size_b} ${list})
        mem_size_b=$((${mem_size_b} / 2 ))
    done

    echo ${list}

    return 0
}

function do_test_eeprom() {

    local sys_path="$1"
    local mem_size_b="$2"
    local size

    for size in $(list_test_byte_amounts ${mem_size_b}) ; do

        # let's clean up
        rm -f ${TMP_DATA_FILE_R} 2>/dev/null
        rm -f ${TMP_DATA_FILE_W} 2>/dev/null

        echo "${FUNCNAME}: info: creating data file of ${size} byte(s)..."
	create_test_data ${TMP_DATA_FILE_W} ${size}
        if [ $? -ne 0 ] ; then
            echo "${FUNCNAME}: error: create_test_data failed"
            return 1
        fi

        echo "${FUNCNAME}: Writing ${size} byte(s) to EEPROM..."
        dd if=${TMP_DATA_FILE_W} of=${sys_path} bs=${size} count=1 >/dev/null 2>&1
        if [ "$?" != 0 ]; then
            echo "${FUNCNAME}: failed to write ${size} byte(s)"
            return 1
        fi

        echo "${FUNCNAME}: Reading ${size} byte(s) from EEPROM..."
        dd if=${sys_path}  of=${TMP_DATA_FILE_R} bs=${size} count=1 >/dev/null 2>&1
        if [ "$?" != 0 ]; then
            echo
            echo "${FUNCNAME}: failed to read ${size} byte(s)"
            return 1
        fi
        
        echo "${FUNCNAME}: comparing ${size} byte(s)..."
        cmp ${TMP_DATA_FILE_W} ${TMP_DATA_FILE_R}
        if [ "$?" != 0 ]; then
            echo "${FUNCNAME}: data mismatch"
            return 1
        fi

    done
    
    return 0
}
