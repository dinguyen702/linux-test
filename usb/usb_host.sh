#!/bin/bash

usage()
{
    cat <<EOF
$(basename $0) [-d usb dev]

Tests the usb host

 -d = usb host device name.  Defaults to $USB_DEV

EOF
}

mount_test()
{
    echo "Mount the USB device"

    mkdir $MOUNTNODE
    mount $DEVNODE $MOUNTNODE
    ret=$?
}

write_test()
{
    echo "Write a random test file."

    CMD="dd if=/dev/urandom of=$MOUNTNODE/$TESTFILE bs=$SIZE count=$FILESIZE"
    echo "$CMD"
    $CMD
    ret=$?

    if [ "$ret" != '0' ]; then
	echo "FAIL - return code is $ret"
	status_fail=1
    fi
}

copy_test()
{
   echo "READ TEST: Copy the random test file."

   cd ~
   CMD="cp $MOUNTNODE/$TESTFILE ."
   echo "$CMD"
   $CMD
   ret=$?

   if [ "$ret" != '0' ]; then
	echo "FAIL - return code is $ret"
	status_fail=1
   fi
}

compare_test()
{
   echo "COMPARE TEST: compare the random test file"

   CMD="cmp $TESTFILE $MOUNTNODE/$TESTFILE"
   echo "$CMD"
   $CMD
   ret=$?

   if [ "$ret" != '0' ]; then
	echo "FAIL - return code is $ret"
	status_fail=1
   fi
}

unmount_test()
{
   echo "Unmount USB device."

   CMD="rm $MOUNTNODE/$TESTFILE"
   echo "$CMD"
   $CMD
   CMD="rm $TESTFILE"
   echo "$CMD"
   $CMD
   CMD="umount $MOUNTNODE"
   echo "$CMD"
   $CMD
}

#===========================================================
echo "USB Host test"
echo

USB_DEV=sda1
status_fail=0

while [ -n "$1" ]; do
    case $1 in
	-d ) USB_DEV=$2 ; shift ;;
	-h|--help ) usage ; exit 1 ;;
    esac
    shift
done

DEVNODE=/dev/$USB_DEV

if [ -z "$DEVNODE" ] || [ ! -e "$DEVNODE" ]; then
    echo "Error cannot find devnode $DEVNODE"
    exit 1
fi

MOUNTNODE=/mnt/hdd1
TESTFILE=usbtestfile
SIZE=1M
FILESIZE=50

mount_test
write_test
copy_test
compare_test
unmount_test

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit 0
