#!/bin/sh

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
    overlay_dir=$1
    dtbo=$2

    echo "Applying overlay ${dtbo}"

    if [ -e $OVERLAYS/${overlay_dir} ]; then
	exit_error "Overlay $foo already exists"
    fi

    dtbt -a ${dtbo}
    exit_if_fail $? "dtbt -a ${dtbo}"
}

function remove_overlay()
{
    foo=$1

    echo removing overlay $foo

    dtbt -r $foo
    exit_if_fail $? "dtbt -r $foo"
}

function remove_all_overlays()
{
    dtbt -r all
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

function bridge_state()
{
    br=$1
    expected=$2

    name="$(cat ${br}/name)"
    value="$(cat ${br}/state)"

    echo "FPGA bridge ${name} ($(basename $br)) state = $value"
    if [ "$value" == "$expected" ]; then
	echo "Correct"
    else
	echo "ERROR - expected $expected"
	status_fail=1
    fi
    echo
}

function usage()
{
    cat <<EOF
$(basename $0)

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

FPGA_DEV=fpga0
status_fail=0

echo "FPGA Manager Test"
echo

case "$(get_devkit_type)" in
    CycloneV ) MGR_NAME="Altera SOCFPGA FPGA Manager"
	       RBF_NAME=soc_system-fpga-mgr-test-c5-1.rbf.gz
	;;
    ArriaV )   echo "Board not supported for test"; exit 1;;
    Arria10 )  echo "Board not supported for test"; exit 1;;
    * )        echo "ERROR - unable to identify board from /proc."
	       exit 1 ;;
esac

while [ -n "$1" ]; do
    case $1 in
	* ) usage ; exit 1 ;;
    esac
    shift
done

DEVNODE=/dev/$FPGA_DEV
FPGA_MGR_SYSFS=/sys/class/fpga_manager/fpga0
CONFIGFS=/sys/kernel/config
OVERLAYS=${CONFIGFS}/device-tree/overlays

#=======================================================================
# Start testing
#

# Set up some file under /lib/firmware
bash_cmd 'cp *.dtb.o /lib/firmware'
bash_cmd "cp $RBF_NAME /lib/firmware"
bash_cmd 'cd /lib/firmware'
bash_cmd "gunzip -f $RBF_NAME"
bash_cmd 'cd -'
echo

# Test that configfs interface is present
path_test ${CONFIGFS}
exit_if_fail $status_fail "/config not found."

path_test ${OVERLAYS}
exit_if_fail $status_fail "/config/device-tree/overlays not found."

# Test that FPGA Manager shows up in sysfs
path_test $FPGA_MGR_SYSFS/name
path_test $FPGA_MGR_SYSFS/state
sysfs_cat_test $FPGA_MGR_SYSFS/name "$MGR_NAME"
exit_if_fail $status_fail "FPGA manager not showing up in sysfs"

# Test that FPGA bridges show up
path_test /sys/class/fpga_bridge/br0
path_test /sys/class/fpga_bridge/br1
sysfs_cat_test /sys/class/fpga_bridge/br0/name lwhps2fpga
sysfs_cat_test /sys/class/fpga_bridge/br1/name hps2fpga

# Apply an overlay
apply_overlay 0 socfpga_c5_overlay_1.dtb.o

# Check bridge state
bridge_state /sys/class/fpga_bridge/br0 enabled
bridge_state /sys/class/fpga_bridge/br1 enabled

# Check FPGA state
sysfs_cat_test $FPGA_MGR_SYSFS/state 'operating'

# Remove an overlay
remove_overlay socfpga_c5_overlay_1.dtb.o

# Check bridge state
bridge_state /sys/class/fpga_bridge/br0 disabled
bridge_state /sys/class/fpga_bridge/br1 disabled

#================================================================
# All done.
#

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
