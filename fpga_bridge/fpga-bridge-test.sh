#!/bin/bash

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

    fpga2sdram0=$(cat fpga2sdram0/enable)
    fpga2sdram1=$(cat fpga2sdram1/enable)
    fpga2sdram2=$(cat fpga2sdram2/enable)
    fpga2sdram3=$(cat fpga2sdram3/enable)

    echo "sdrctl=$sdrctl : enables = $fpga2sdram0 $fpga2sdram1 $fpga2sdram2 $fpga2sdram3"
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

#==============================
dmesg | grep bridge
echo
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
