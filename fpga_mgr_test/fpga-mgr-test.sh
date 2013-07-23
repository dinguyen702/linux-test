#!/bin/bash

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
	echo "FAIL - return code is $ret"
	return $ret
    fi

    return $ret
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
	echo "FAIL - return code is $ret"
	return $ret
    fi

    echo "status = $status"
    if [ "$status" != "$expected" ]; then
	echo "Error, expected FPGA to be in power up phase.  status = $status"
	if [ "$expected" == 'power up phase' ]; then
	    echo "need to power cycle possibly."
	fi
	return 1
    fi

    return 0
}

name_test()
{
    expected=$1

    echo "getting status"
    CMD="cat /sys/class/fpga/$FPGA_DEV/name"
    echo "$CMD"
    status=$($CMD)
    ret=$?

    if [ "$ret" != '0' ]; then
	echo "FAIL - return code is $ret"
	return $ret
    fi

    echo "name = $status"
    if [ "$status" != "$expected" ]; then
	echo "Error, expected name to be $expected."
	return 1
    fi

    return 0
}

exit_if_error()
{
    ret=$1
    if [ "$ret" != '0' ]; then
	echo "FAIL"
	exit $ret
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

while [ -n "$1" ]; do
    case $1 in
	-i ) RAW_IMAGE=$2 ; shift ;;
	-d ) FPGA_DEV=$2 ; shift ;;
	-h|--help ) usage ; exit 1 ;;
    esac
    shift
done
DEVNODE=/dev/$FPGA_DEV

if [ -z "$DEVNODE" ] || [ ! -e "$DEVNODE" ]; then
    echo "Error cannot find devnode $DEVNODE"
    exit 1
fi
if [ -z "$RAW_IMAGE" ] || [ ! -e "$RAW_IMAGE" ]; then
    echo "Error cannot find image file $RAW_IMAGE"
    exit 1
fi

name_test 'Altera FPGA Manager'
exit_if_error $?

status_test 'power up phase'
exit_if_error $?

echo
program_fpga
exit_if_error $?

echo
status_test 'user mode'
exit_if_error $?

echo "PASS"
exit 0
