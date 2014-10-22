#!/bin/bash

MACHINE="$(cat /proc/device-tree/model)"
CPUINFO="/proc/cpuinfo"
CMDLINE="$(cat /proc/cmdline)"


# Returns the list of CPU indexes a SoC features
# Starts at 0
function get_soc_cpu_list() {

    if [[ "${MACHINE}" =~ (Arria V|Cyclone V)  ]] ; then 
        echo 0 1
        return 0 
    fi
    # Other SoC's will be added here 

    return 1
}

# Retuns the number of CPU's a SoC supports.
# This is the number of physical CPU's
function get_soc_max_num_cpus() {

    get_soc_cpu_list | wc -w
   
    return ${PIPESTATUS[0]}
}

# Checking the command line and uname to see how many cpus are expected
# to be in use
function get_num_expected_cpus() {
    
    local cmd_cpus
    local cpus

    cmd_cpus=$(echo ${CMDLINE} | egrep -o -e 'maxcpus=[0-9]+|nosmp')
    if [ $(echo ${cmd_cpus} | wc -w) -gt 1 ] ; then
        echo "${FUNCNAME}: error: ambiguous kernel command line: ${CMDLINE}"
        return 1
    fi

    if [[ "${cmd_cpus}" =~ nosmp ]] ; then
       cpus=1
    else if [[ "${cmd_cpus}" =~ maxcpus ]] ; then
            # maxcpus=[0-9]+
            cpus=$(echo ${cmd_cpus} | awk -F= ' { print $2 } ')
            if [ -z ${cpus} ] ; then
                echo "${FUNCNAME}: error: misuse of maxcpus: ${cmd_cpus}"
                return 1
            fi 
         else 
            # the kernel may or may not be SMP
            if [[ "$(uname -v)" =~ SMP ]] ; then
                cpus=$(get_soc_max_num_cpus)
            else
                # non SMP kernel, 1 CPU only
                cpus=1
            fi 
         fi
    fi 

    echo ${cpus}
    
    return 0
}

# Returns a list of online CPU's
function get_list_online_cpus() {

    cat ${CPUINFO} | egrep '^processor' | awk -F: ' { printf $2 } '
    
}

# Returns the number of online CPU's
function get_num_online_cpus() {
    
    get_list_online_cpus | wc -w

}

# Returns a non empty line if a cpu is online
# $1 = CPU index
function cpu_is_present() {

    local cpu="$1"

    cat ${CPUINFO} | egrep "^processor.\s*: ${cpu}\$" 

}

# Prints 0 is a CPU is online
# $1 = CPU index
function is_cpu_online() {

    local cpu=${1}
    local tmpa

    tmpa=$(cpu_is_present ${cpu})
    if [ -z "${tmpa}" ] ; then
        echo 1
    else
        echo 0
    fi
}

# Shutdown CPU
# $1 = CPU index
# Returns 0 on success
function shutdown_cpu() {
    local cpu=${1}

    echo 0 > /sys/devices/system/cpu/cpu${cpu}/online

    return $?
}

# Brings a cpu up
# $1 = CPU index
# Returns 0 on success
function bringup_cpu() {

    local cpu=${1}

    echo 1 >  /sys/devices/system/cpu/cpu${cpu}/online

    return $?
}


