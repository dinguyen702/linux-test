#!/bin/bash

function get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    # Altera SOCFPGA Arria 10 ==> Arria10
    cat /proc/device-tree/model | cut -d ' ' -f 3-4 | tr -d ' '
}

# Exit with error msg
function exit_error()
{
    echo "FAIL - $@"
    exit 1
}

# Exit with error message if status_fail shows error
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

    echo "Applying overlay ${dtbo}"

    dtbt ${DTBO_DIR} -a ${dtbo}
    exit_if_fail $? "dtbt -a ${dtbo}"
}

function remove_overlay()
{
    foo=$1

    echo removing overlay $foo

    dtbt -r $foo
    exit_if_fail $? "dtbt -r $foo"
}

#todo not error, but status_fail
function check-sysid()
{
    addr=$1
    expected=$2
    path=/sys/bus/platform/drivers/altera_sysid/${addr}.sysid

    if [ -z "$expected" ]; then
	if [ ! -f "${path}" ];then
	    echo "GOOD:  $path expected to not exist and does not exist"
	else
	    echo "ERROR: $path expected to not exist and exists"
	    status_fail=1
	fi
	return
    fi
    
    got="$(cat ${path}/sysid/id)"
    if [ "$expected" == "$got" ]; then
	echo "GOOD:  $path == $got"
    else
	echo "ERROR: $path == $got (expected $expected)"
	status_fail=1
    fi
}

function path_test()
{
    path=$1
    if [ -e "$path" ]; then
	echo "path exists: $path"
    else
	echo "FAIL - path does not exist: $path"
	status_fail=1
    fi
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
	echo "ERROR - return code is $ret"
	status_fail=1
    fi

    echo "value = $value"
    if [ "$value" == "$expected" ]; then
	echo "Correct"
    else
	echo "ERROR - expected FPGA to be in $expected phase.  value = $value"
	if [ "$expected" == 'power up phase' ]; then
	    echo "need to power cycle possibly."
	fi
	status_fail=1
    fi
    echo
}

function usage()
{
    cat <<EOF
$(basename $0) [--ghrd-release]

Specify --ghrd-release if running test on an unmodified ghrd release.

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

#===========================================================
# Set up constants for the test
#

status_fail=0

echo "Sysid test on Arria 10"
echo

case "$(get_devkit_type)" in
    Arria10 )  ;;
    * )        echo "Board not supported for test"; exit 1;;
esac

unmodified=
while [ -n "$1" ]; do
    case $1 in
	--ghrd-release ) ghrd=1 ;;
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
    STATICREGION=socfpga_arria10_socdk_sdmmc_ghrd_ovl_ext_cfg.dtb
    PERSONA0=socfpga_arria10_socdk_sdmmc_ghrd_ovl.dtb
    PERSONA1=socfpga_arria10_socdk_sdmmc_ghrd_persona_ovl.dtb
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
exit_if_fail $status_fail "/config not found."

path_test ${OVERLAYS}
exit_if_fail $status_fail "/config/device-tree/overlays not found."

# Test that FPGA Manager shows up in sysfs
path_test $FPGA_MGR_SYSFS/name
path_test $FPGA_MGR_SYSFS/state
#sysfs_cat_test $FPGA_MGR_SYSFS/name "$MGR_NAME"
exit_if_fail $status_fail "FPGA manager not showing up in sysfs"

#------------------------------------------------------------

echo "No overlays yet"
echo
ls /sys/class/fpga_region/ -l
echo

sleep 1
if [ -n "$STATICREGION" ]; then
    echo "Applying ext cfg overlay : $STATICREGION"
    apply_overlay ${STATICREGION}
fi
    sysfs_cat_test $FPGA_MGR_SYSFS/state 'operating'
    echo
ls /sys/class/fpga_region/ -l
check-sysid ff200000 3221756416
check-sysid ff200800
check-sysid ff200900
echo

echo "Applying overlay : $PERSONA0"
apply_overlay ${PERSONA0}
sysfs_cat_test $FPGA_MGR_SYSFS/state 'operating'
echo
ls /sys/class/fpga_region/ -l
check-sysid ff200000 3221756416
check-sysid ff200800 3405707982
check-sysid ff200900
echo

echo "Removing overlay : $PERSONA0"
remove_overlay ${PERSONA0}
ls /sys/class/fpga_region -l
check-sysid ff200000 3221756416
check-sysid ff200800
check-sysid ff200900
echo

echo "Applying overlay : $PERSONA1"
apply_overlay ${PERSONA1}
sysfs_cat_test $FPGA_MGR_SYSFS/state 'operating'
ls /sys/class/fpga_region -l
check-sysid ff200000 3221756416
check-sysid ff200800
check-sysid ff200900 4207856382
echo

remove_overlay ${PERSONA1}
ls /sys/class/fpga_region/ -l
check-sysid ff200000 3221756416
check-sysid ff200800
check-sysid ff200900

if [ -n "$STATICREGION" ]; then
    echo "Removing ext cfg overlay : $STATICREGION"
    remove_overlay ${STATICREGION}
fi
ls /sys/class/fpga_region/ -l
check-sysid ff200000
check-sysid ff200800
check-sysid ff200900

#================================================================
# All done.
#

echo
uname -a
echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
