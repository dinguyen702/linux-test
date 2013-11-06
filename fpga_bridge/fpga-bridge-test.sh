#!/bin/bash

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

toggle()
{
    status=$(cat $1/enable)
    case $status in
	0 ) status=1 ;;
	1 ) status=0 ;;
	* ) echo "what?"; exit 1 ;;
    esac
    echo $status > $1/enable
}

exit_if_fail()
{
    ret=$1
    if [ "$ret" != '0' ]; then
	echo "FAIL - return code is $ret"
	exit
    fi
}

#==============================

RAW_IMAGE=paris_hardware.rbf.gz
FPGA_DEV=fpga0
READ_SYSID=

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

dmesg | grep bridge
echo

echo "gunzip -c $RAW_IMAGE | dd of=/dev/$FPGA_DEV bs=1M"
gunzip -c $RAW_IMAGE | dd of=/dev/$FPGA_DEV bs=1M
exit_if_fail $?

echo
cd /sys/class/fpga-bridge
ls -1
for foo in fpga2hps hps2fpga lwhps2fpga
do
    echo "enable $foo"
    toggle $foo
    dump_rstmgr
    echo
    echo "disable $foo"
    toggle $foo
    dump_rstmgr
    echo
done
echo
for foo in *sdram*
do
    echo "enable $foo"
    toggle $foo
    dump_sdrctl
    echo
    echo "disable $foo"
    toggle $foo
    dump_sdrctl
    echo
done

echo "enabling lw bridge"
echo 1 > /sys/class/fpga-bridge/lwhps2fpga/enable
exit_if_fail $?

if [ -n "$READ_SYSID" ]; then
    echo "reading sysid"
    memtool -32 0xff210000 1
    exit_if_fail $?
fi

echo
echo "PASS"
