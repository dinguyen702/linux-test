#!/bin/sh

get_devkit_type()
{
    # Altera SOCFPGA Arria V SoC Development Kit   ==> ArriaV
    # Altera SOCFPGA Cyclone V SoC Development Kit ==> CycloneV
    # Altera SOCFPGA Arria 10 ==> Arria10
    cat /proc/device-tree/model | cut -d ' ' -f 3-4 | tr -d ' '
}

function read_image() {
    echo "Checking that the image debugfs file is w/o (should complain):"
    cat /sys/kernel/debug/fpga_manager/fpga0/image
    if [ $? -eq 0 ]; then
	echo "ERROR, reading image file should have failed"
	status=1
    else
	echo "Good!"
    fi
    echo
}

function write_firmware() {
    echo "Writing FPGA using firmware_name debugfs file"
    echo ${image} > /sys/kernel/debug/fpga_manager/fpga0/firmware_name
    if [ $? -ne 0 ]; then
	echo "ERROR"
	status=1
    fi

    fw=$(cat /sys/kernel/debug/fpga_manager/fpga0/firmware_name)
    if [ $? -ne 0 ]; then
	echo "ERROR status while reading back firmware_name"
	status=1
    fi

    if [ "${fw}" != "${image}" ]; then
	echo "ERROR - firmware_name read back is wrong"
	status=1
    fi
    check_state 'operating'
    echo
}

function write_image() {
    echo "Writing FPGA using image debugfs file"
    dd bs=10M if=/lib/firmware/${image} of=/sys/kernel/debug/fpga_manager/fpga0/image
    if [ $? -ne 0 ]; then
	echo "ERROR"
	status=1
    fi

    fw=$(cat /sys/kernel/debug/fpga_manager/fpga0/firmware_name)
    if [ $? -ne 0 ]; then
	echo "ERROR status while reading back firmware_name"
	status=1
    fi

    if [ "${fw}" != "" ]; then
	echo "ERROR - firmware_name read back should have been blank"
	status=1
    fi
    check_state 'operating'
    echo
}

function path_test() {
    path=${1}
    if [ -e "$path" ]; then
	echo "path exists: $path"
    else
	echo "FAIL - path does not exist: $path"
	status=1
    fi
    echo
}

function check_state() {
    expected="${1}"

    state="$(cat /sys/class/fpga_manager/${fpga_dev}/state)"
    ret=$?

    if [ "${ret}" != '0' ]; then
	echo "ERROR - return code is $ret"
	status=1
    fi

    echo "state = ${state}"
    if [ "${state}" != "${expected}" ]; then
	echo "ERROR - expected FPGA to be in ${expected} phase.  state = ${state}"
	status=1
    fi
}

function usage() {
    cat <<EOF
$(basename $0) [-i FPGA image file][-d fpga dev]

 -i = file to program to FPGA. Defaults to $RAW_IMAGE
 -d = FPGA device name.  Defaults to $FPGA_DEV

EOF
}

#===========================================================
echo "FPGA Manager DebugFS Test"
echo
echo " - requires recompile to enable CONFIG_FPGA_MGR_DEBUG_FS=y"
echo

case "$(get_devkit_type)" in
#    ArriaV )   RAW_IMAGE=ghrd_5asxfb5h4.rbf.gz
#               MGR_NAME='Altera FPGA Manager'
#	       ;;
    CycloneV ) image=soc_system-fpga-mgr-test-c5-1.rbf
               MGR_NAME='Altera FPGA Manager'
	       ;;
#    Arria10 )  image=
#               MGR_NAME='SoCFPGA Arria10 FPGA Manager'
#	       ;;
    * )        echo "ERROR - unable to identify board from /proc."
	       exit 1 ;;
esac

fpga_dev=fpga0
status=0

while [ -n "$1" ]; do
    case $1 in
	-i ) image=$2 ; shift ;;
	-d ) fpga_dev=$2 ; shift ;;
	-h|--help ) usage ; exit 1 ;;
    esac
    shift
done

if [ -n "$image" ]; then
    path_test $image
fi

path_test /sys/kernel/debug/fpga_manager/${fpga_dev}/image
path_test /sys/kernel/debug/fpga_manager/${fpga_dev}/flags
path_test /sys/kernel/debug/fpga_manager/${fpga_dev}/firmware_name

blksize=10M

read_image

write_firmware

write_image

write_firmware

write_image

echo
if [ "$status" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status
