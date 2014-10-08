#!/bin/sh

usage()
{
    cat <<EOF
$(basename $0) [-i FPGA image file][-d fpga dev]

 -i = file to program to FPGA. Defaults to $RAW_IMAGE
 -s = read sysid. Only works with images that include sysid.
      ***will hang the board on all other images***
 -d = FPGA device name.  Defaults to $FPGA_DEV

EOF
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

readreg()
{
    memtool -32 $1 1 2>&1|grep :|cut -d: -f2|sed 's/ //g'
}

dump_rstmgr()
{
    rstmgr=$(readreg 0xffd0501c)

    # Note that the bits in the L3 interconnect reg are WRITE-ONLY (0xff800000)
    # So we can't read back and test them here.

    fpga2hps=$(cat fpga2hps/enable)
    hps2fpga=$(cat hps2fpga/enable)
    lwhps2fpga=$(cat lwhps2fpga/enable)

    echo "rstmgr=$rstmgr : enables = fpga2hps=$fpga2hps hps2fpga=$hps2fpga lwhps2fpga=$lwhps2fpga"
}

dump_sdrctl()
{
    sdrctl=$(readreg 0xffc25080)

    fpga2sdram=$(cat fpga2sdram/enable)

    echo "sdrctl=$sdrctl : enables = $fpga2sdram"
}

test_return_code()
{
    ret=$1
    if [ "$ret" != '0' ]; then
	echo "ERROR - return code is $ret"
	status_fail=1
    fi
}

check_enable()
{
    if [ -n "$2" ]; then
	echo "Verify that $1/enable == $2"
    else
	echo "Verify that $1/enable is 0 or 1 at least."
    fi
    status=$(cat $1/enable)
    case $status in
	0 ) ;;
	1 ) ;;
	* ) echo "ERROR Invalid enable value read from $1/enable: $status";
	    status_fail=1;;
    esac
    if [ -n "$2" ]; then
	if [ "$2" != "$status" ]; then
	    echo "ERROR expected enable = $2, but read $status"
	    status_fail=1
	fi
    fi
}

set_enable()
{
    case $2 in
	0 ) echo "disable $foo" ;;
	1 ) echo "enable $foo" ;;
    esac
    echo $2 > $1/enable
    test_return_code $?
}

#==============================

RAW_IMAGE=paris_hardware.rbf.gz
FPGA_DEV=fpga0
READ_SYSID=
status_fail=0

while [ -n "$1" ]; do
    case $1 in
	-i ) RAW_IMAGE=$2 ; shift ;;
	-d ) FPGA_DEV=$2 ; shift ;;
	-s ) READ_SYSID=1 ;;
	-h|--help ) usage ; exit 1 ;;
    esac
    shift
done
DEVNODE=/dev/$FPGA_DEV

path_test /sys/class/fpga-bridge
path_test /sys/class/fpga-bridge/fpga2hps
path_test /sys/class/fpga-bridge/fpga2hps/enable
path_test /sys/class/fpga-bridge/hps2fpga
path_test /sys/class/fpga-bridge/hps2fpga/enable
path_test /sys/class/fpga-bridge/lwhps2fpga
path_test /sys/class/fpga-bridge/lwhps2fpga/enable
path_test /sys/class/fpga-bridge/fpga2sdram
path_test /sys/class/fpga-bridge/fpga2sdram/enable

# Program the FPGA
echo "gunzip -c $RAW_IMAGE | dd of=/dev/$FPGA_DEV bs=1M"
gunzip -c $RAW_IMAGE | dd of=/dev/$FPGA_DEV bs=1M
test_return_code $?

echo
cd /sys/class/fpga-bridge
ls -1
echo
for foo in fpga2hps hps2fpga lwhps2fpga
do
    check_enable $foo
    set_enable $foo 1
    check_enable $foo 1
    dump_rstmgr
    echo
    set_enable $foo 0
    check_enable $foo 0
    dump_rstmgr
    echo
done
echo
for foo in *sdram*
do
    check_enable $foo
    set_enable $foo 1
    check_enable $foo 1
    dump_sdrctl
    echo
    set_enable $foo 0
    check_enable $foo 0
    dump_sdrctl
    echo
done

echo "enabling lw bridge"
echo 1 > /sys/class/fpga-bridge/lwhps2fpga/enable
test_return_code $?

if [ -n "$READ_SYSID" ]; then
    echo "reading sysid"
    memtool -32 0xff210000 1
    test_return_code $?
fi

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
