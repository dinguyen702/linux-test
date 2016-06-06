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

    mkdir $OVERLAYS/${overlay_dir}
    exit_if_fail $? "mkdir $OVERLAYS/${overlay_dir}"

    echo ${dtbo} > $OVERLAYS/${overlay_dir}/path
    exit_if_fail $? "echo ${dtbo} > $OVERLAYS/${overlay_dir}/path"

    if [ "$(cat $OVERLAYS/${overlay_dir}/status)" != 'applied' ]; then
	exit_error "overlay status is $(cat $OVERLAYS/${overlay_dir}/status)"
    fi
}

function remove_overlay()
{
    foo=$1

    if [ ! -e $OVERLAYS/$foo ]; then
	status_fail=1
    fi	

    echo removing overlay $foo

    rmdir $OVERLAYS/$foo
    exit_if_fail $? "rmdir $OVERLAYS/$foo"
}

function remove_all_overlays()
{
    for foo in 3 2 1 0; do
	remove_overlay $foo
    done
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
OVERLAYS=/config/device-tree/overlays

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
path_test /config
exit_if_fail $status_fail "/config not found."

path_test /config/device-tree/overlays
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
sysfs_cat_test /sys/class/fpga_bridge/br0/state enabled
sysfs_cat_test /sys/class/fpga_bridge/br1/state enabled

# Check FPGA state
sysfs_cat_test $FPGA_MGR_SYSFS/state 'operating'

# Remove an overlay
remove_overlay 0

# Check bridge state
sysfs_cat_test /sys/class/fpga_bridge/br0/state disabled
sysfs_cat_test /sys/class/fpga_bridge/br1/state disabled

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
