#!/bin/bash

default_runs=20

function get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    # Altera SOCFPGA Arria 10 ==> Arria10
    # 10SoCDK
    cat /proc/device-tree/model | cut -d ' ' -f 3-4 | tr -d ' '
}

# Exit with error msg
function exit_error()
{
    echo "FAIL - during test run number $repeat_count - $@"
    exit 1
}

function exit_if_fail()
{
    status=$1
    shift
    if [ "$status" != 0 ]; then
	exit_error $@
    fi
}

function apply_overlay()
{
    dtbo=$1
    dtbt ${DTBO_DIR} -a ${dtbo}
    exit_if_fail $? "dtbt -a ${dtbo}"
}

function remove_overlay()
{
    foo=$1
    dtbt -r $foo
    exit_if_fail $? "dtbt -r $foo"
}

function check-sysid()
{
    addr=${sysid_addrs[$1]}
    if [ ${addr} -eq 0 ]; then
	echo "skipping base sysid (nonexistant)"
	return
    fi
    expected=$2
    path=/sys/bus/platform/drivers/altera_sysid/${addr}.sysid

    if [ -z "$expected" ]; then
	if [ -f "${path}" ];then
	    exit_error "ERROR: $path expected to not exist and exists"
	fi
	echo "GOOD:  $path expected to not exist and does not exist"
	return
    fi
    
    got="$(cat ${path}/sysid/id)"
    if [ "$expected" != "$got" ]; then
	exit_error "$path == $got (expected $expected)"
    fi
    echo "GOOD:  $path == $got"
}

function path_test()
{
    path=$1
    if [ ! -e "$path" ]; then
	exit_error "path does not exist: $path"
    fi
    echo "path exists: $path"
}

function sysfs_cat_test()
{
    path=$1
    expected=$2

    echo
    echo "getting $path"
    CMD="cat $path"
    echo "$CMD"
    value=$($CMD)
    ret=$?
    if [ "$ret" != '0' ]; then
	exit_error "return code is $ret"
    fi

    echo "value = $value"
    if [ "$value" != "$expected" ]; then
	if [ "$expected" == 'power up phase' ]; then
	    echo "need to power cycle possibly."
	fi
	exit_error "expected FPGA to be in $expected phase.  value = $value"
    fi
    echo "Correct"
    echo
}

function usage()
{
    cat <<EOF
$(basename $0) [--ghrd-release] [-n number of test runs}

Specify --ghrd-release if running test on an unmodified ghrd release.

-n 10 = run test 10 times.  Note that default is $default_runs

The A10 PR reference design that can be found on rocketboards at
https://rocketboards.org/foswiki/Projects/Arria10SoCHardwareReferenceDesignThatDemostratesPartialReconfiguration#A_42Release_Contents_42

EOF
}

function bash_cmd()
{
    echo "$ $@"
    $@
    exit_if_fail $? $@
}

function sysid_test()
{
    if [ -n "$STATICREGION" ]; then
	apply_overlay ${STATICREGION}
    fi
    echo
    ls /sys/class/fpga_region/ -l
    check-sysid 0 3221756416
    check-sysid 1
    check-sysid 2
    echo

    apply_overlay ${PERSONA0}
    sysfs_cat_test $FPGA_MGR_SYSFS/state 'operating'
    echo
    ls /sys/class/fpga_region/ -l
    check-sysid 0 3221756416
    check-sysid 1 3405707982
    check-sysid 2
    echo

    remove_overlay ${PERSONA0}
    ls /sys/class/fpga_region -l
    check-sysid 0 3221756416
    check-sysid 1
    check-sysid 2
    echo

    apply_overlay ${PERSONA1}
    sysfs_cat_test $FPGA_MGR_SYSFS/state 'operating'
    ls /sys/class/fpga_region -l
    check-sysid 0 3221756416
    check-sysid 1
    check-sysid 2 4207856382
    echo

    remove_overlay ${PERSONA1}
    ls /sys/class/fpga_region/ -l
    check-sysid 0 3221756416
    check-sysid 1
    check-sysid 2

    if [ -n "$STATICREGION" ]; then
	remove_overlay ${STATICREGION}
    fi
    ls /sys/class/fpga_region/ -l
    check-sysid 0
    check-sysid 1
    check-sysid 2
}

#===========================================================
# Set up constants for the test
#

echo "Sysid test"
echo

case "$(get_devkit_type)" in
    Arria10 )
	sysid_addrs=(ff200000 ff200800 ff200900)
	sysid_values=(3221756416 3405707982 4207856382)
	STATICREGION=socfpga_arria10_socdk_sdmmc_ghrd_ovl_ext_cfg.dtb
	;;
    10SoCDK )
	sysid_addrs=(0 f9000800 f9000900)
	sysid_values=(0 3405707982 4207856382)
	STATICREGION=base.dtb
	;;
    * )        echo "Board not supported for test"; exit 1;;
esac

repeat=${default_runs}
unmodified=
while [ -n "$1" ]; do
    case $1 in
	--ghrd-release ) ghrd=1 ;;
	-n ) repeat=$2; shift ;;
	* ) usage ; exit 1 ;;
    esac
    shift
done

FPGA_MGR_SYSFS=/sys/class/fpga_manager/fpga0
CONFIGFS=/sys/kernel/config
OVERLAYS=${CONFIGFS}/device-tree/overlays

if [ -n "$ghrd" ]; then
    DTBO_DIR="-p /boot"
    STATICREGION=
    PERSONA0=persona0.dtbo
    PERSONA1=persona1.dtbo
else
    DTBO_DIR=
    PERSONA0=persona0.dtb
    PERSONA1=persona1.dtb
fi

#=======================================================================
# Start testing
#

# Set up some file under /lib/firmware
#bash_cmd "cp alternate_persona.pr_partition.rbf /lib/firmware"
#bash_cmd "cp ghrd_10as066n2.pr_partition.rbf /lib/firmware"
#todo
#bash_cmd 'cp *.dtb.o /lib/firmware'
echo

# Test that configfs interface is present
path_test ${CONFIGFS}
path_test ${OVERLAYS}

# Test that FPGA Manager shows up in sysfs
path_test $FPGA_MGR_SYSFS/name
path_test $FPGA_MGR_SYSFS/state

echo "No overlays yet"
echo
ls /sys/class/fpga_region/ -l
echo

sleep 1
let repeat_count=0
while [ "$repeat" -gt "$repeat_count" ]; do
    let repeat_count=repeat_count+1
    echo "=================================================================================================="
    echo "test run number $repeat_count"
    echo
    sysid_test
    echo
done
echo "=================================================================================================="

echo
uname -a
echo
echo "PASS"
exit 0
