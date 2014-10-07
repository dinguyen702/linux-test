#!/bin/sh

program_fpga()
{
    echo "Programming FPGA with $RAW_IMAGE"

    case $RAW_IMAGE in
	*.gz )
	    echo "gunzip -c $RAW_IMAGE | dd of=$DEVNODE bs=$BLKSIZE"
	    gunzip -c $RAW_IMAGE | dd of=$DEVNODE bs=$BLKSIZE
	    ret=$?
	    ;;

	* )
	    CMD="dd if=$RAW_IMAGE of=$DEVNODE bs=$BLKSIZE"
	    echo "$CMD"
	    $CMD
	    ret=$?
	    ;;
    esac

    if [ "$ret" != '0' ]; then
	echo "ERROR - return code is $ret"
	status_fail=1
    fi
}

path_test()
{
    path=$1
    if [ -e "$path" ]; then
	echo "path exists: $path"
    else
	echo "FAIL - path does not exist: $path"
	status_fail=1
    fi
}

status_test()
{
    expected=$1

    echo "getting status"
    CMD="cat /sys/class/fpga/$FPGA_DEV/status"
    echo "$CMD"
    status=$($CMD)
    ret=$?

    if [ "$ret" != '0' ]; then
	echo "ERROR - return code is $ret"
	status_fail=1
    fi

    echo "status = $status"
    if [ "$status" != "$expected" ]; then
	echo "ERROR - expected FPGA to be in $expected phase.  status = $status"
	if [ "$expected" == 'power up phase' ]; then
	    echo "need to power cycle possibly."
	fi
	status_fail=1
    fi
}

name_test()
{
    expected=$1

    echo "getting name"
    CMD="cat /sys/class/fpga/$FPGA_DEV/name"
    echo "$CMD"
    name=$($CMD)
    ret=$?

    if [ "$ret" != '0' ]; then
	echo "FAIL - return code is $ret"
	status_fail=1
    fi

    echo "name = $name"
    if [ "$name" != "$expected" ]; then
	echo "Error, expected name to be $expected."
	status_fail=1
    fi
}

usage()
{
    cat <<EOF
$(basename $0) [-i FPGA image file][-d fpga dev]

 -i = file to program to FPGA. Defaults to $RAW_IMAGE
 -d = FPGA device name.  Defaults to $FPGA_DEV

EOF
}

#===========================================================
echo "FPGA Manager Test"
echo

BLKSIZE='1M'
RAW_IMAGE=paris_hardware.rbf.gz
FPGA_DEV=fpga0
status_fail=0

while [ -n "$1" ]; do
    case $1 in
	-i ) RAW_IMAGE=$2 ; shift ;;
	-d ) FPGA_DEV=$2 ; shift ;;
	-h|--help ) usage ; exit 1 ;;
    esac
    shift
done

DEVNODE=/dev/$FPGA_DEV
SYSFS=/sys/class/fpga/fpga0

path_test $DEVNODE
path_test $RAW_IMAGE
path_test $SYSFS/name
path_test $SYSFS/status

name_test 'Altera FPGA Manager'
echo

#status_test 'power up phase'
#echo

program_fpga
echo

status_test 'user mode'

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
