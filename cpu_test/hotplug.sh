#!/bin/bash

# internals
SELF=$(basename $0)
SELF_DIR=$(dirname $0)
CONST_CMD_CPU_UP="bringup_cpu"
CONST_CMD_CPU_DOWN="shutdown_cpu"

CONST_TEST_SUCCESS="success"
CONST_TEST_FAILURE="failure"

# test specific
ITERATIONS=10000              

declare -a CPU_STATE

# library of functions
source ${SELF_DIR}/libcpu.sh

init_env() {

     local soc_cpu_list=$(get_soc_cpu_list)
     local cpu
     local cpu_count=0

     for cpu in ${soc_cpu_list} ; do
     
         CPU_STATE[${cpu}]=$(is_cpu_online ${cpu})
         if [ ${CPU_STATE[${cpu}]} -eq 0 ] ; then
             cpu_count=$((${cpu_count} + 1))
         fi
     done

     if  [ ${cpu_count} -ne $(get_num_expected_cpus) ] ; then
         #  given the kernel command line, there's a mismatch in #
         #  of expected CPU's being online
        echo "${FUNCNAME}: error: mismatch in number of expected CPU's"
        return 1
     fi

     echo "${FUNCNAME}: info: found ${cpu_count} CPU's being online, OK"

     return 0
}

#  command is either ${CONST_CMD_CPU_DOWN} or ${CONST_CMD_CPU_UP}
#  command names returned are actual function names
function get_rand_cmd() {

    local rnd=$(( ${RANDOM} % 2))

    if [ ${rnd} -eq 0 ] ; then
        echo ${CONST_CMD_CPU_DOWN}
    else
        echo ${CONST_CMD_CPU_UP}
    fi
    
    return 0
}

#  get a random CPU from the list of the SoC's possible CPU's
#  which helps cover negative test cases
function get_rand_cpu() {

    local rnd=$(( ${RANDOM} % $(get_soc_max_num_cpus) ))

    echo ${rnd}

    return 0
}

#  assumption: all available CPU's (per kernel command line) are online
#  before we start this function
#  covers positive and negative cases
hotplug_test() {

    local i=0
    local cpu
    local cmd
    local max_cpu=$(get_num_expected_cpus)  # highest index of this runtime
    local expected_result
    local result
    local err=0

    echo "${FUNCNAME}: info: running hotplug test ${IERATIONS} times"

    # repeat ${ITERATIONS} times
    while [ ${i} -lt ${ITERATIONS} ] ; do
        cmd=$(get_rand_cmd)
        cpu=$(get_rand_cpu)

        # Update the expected CPU state array
        case ${cmd} in
            ${CONST_CMD_CPU_DOWN})
                      CPU_STATE[${cpu}]=0
                      ;;
            ${CONST_CMD_CPU_UP})
                      CPU_STATE[${cpu}]=1
		      ;;
        esac

        # if the cpu # picked is higher than max_cpu,
        # then we know failure to execute ${cmd} is expected
        if [ ${cpu} -gt ${max_cpu} ] ; then
             expected_result="${CONST_TEST_FAILURE}"
        else
             if [ ${cpu} -eq 0 -a "${cmd}" == "${CONST_CMD_CPU_DOWN}" ] ; then
                 expected_result="${CONST_TEST_FAILURE}"
             else 
                 expected_result="${CONST_TEST_SUCCESS}"
             fi   
        fi

        # let's execute ${cmd}
        ${cmd} ${cpu}
        result=$?
        if [ ${result} -eq 0 ] ; then
            if [ ${expected_result} == "${CONST_TEST_SUCCESS}" ] ; then
                echo "${FUNCNAME}: info: ${i}: ${cpu}: ${cmd}: OK"
            else 
                echo "${FUNCNAME}: info: ${i}: ${cpu}: ${cmd}: FFFF"
                err=1
            fi 
        else 
            if [ ${expected_result} == "${CONST_TEST_SUCCESS}" ] ; then
                echo "${FUNCNAME}: info: ${i}: ${cpu}: ${cmd}: FFFF"
                err=1
            else 
                echo "${FUNCNAME}: info: ${i}: ${cpu}: ${cmd}: OK"
            fi 
        fi 

        # keep on testing
        i=$(( ${i} + 1 ))
    done

    if [ ${err} -gt 0 ] ; then
        echo "${FUNCNAME}: info: test failed"
    else
        echo "${FUNCNAME}: info: test success"
    fi

    return ${err}
}


echo "${SELF}: info: init'ing env..."
init_env
if [ $? -ne 0 ] ; then
    echo "${SELF}: init_env: failed"
    exit 1
fi

echo "${SELF}: info: starting hotplug test..."
hotplug_test
if [ $? -ne 0 ] ; then
    echo "${SELF}: hotplug_test: failed"
    exit 1
fi

exit 0

