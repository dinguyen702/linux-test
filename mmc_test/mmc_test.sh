#!/bin/sh

readonly TESTFILE=test2G
readonly MOUNTNODE=/mnt/hdd1
readonly DEVNODE=/dev/mmcblk0p4
status_fail=0

usage()
{
   cat <<EOF

This test assumes an NFS and a SD/MMC partition that has > 2GB of free space.
The test will perform the following actions:

- Create a 2GB test file of random data and place it in the home directory
- Mount the p4 partition of /dev/mmcblk0 device
- Write the 2GB test file to the SD card's p4 partition
- Compare the 2 files
- Umounts the SD card
- Deletes the test file 

EOF
}

write_sd_image()
{
    echo "Write testfile to SD card"

    CMD="dd if=$TESTFILE of=$MOUNTNODE/$TESTFILE bs=1M"
    echo "$CMD"
    $CMD
    ret=$?

    if [ "$ret" != '0' ]; then
        echo "FAIL - return code is $ret"
        status_fail=1
   fi
}

mount_card()
{
   echo "Mount the SD partition"

   mkdir $MOUNTNODE
   mount $DEVNODE $MOUNTNODE
}

create_test_file()
{
   echo "Create a random test file"

   CMD="dd if=/dev/urandom of=$TESTFILE bs=1M count=2000"
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
   echo "Compare the test file that was written"

   CMD="diff $TESTFILE $MOUNTNODE/$TESTFILE"
   echo "$CMD"
   $CMD
   ret=$?

   if [ "$ret" != '0' ]; then
        echo "FAIL - return code is $ret"
        status_fail=1
   fi
}

umount_test()
{
   echo "Umount $MOUNTNODE"

   CMD="umount $MOUNTNODE"
   echo "$CMD"
   $CMD
   sync
   ret=$?

   if [ "$ret" != '0' ]; then
        echo "FAIL - return code is $ret"
        status_fail=1
   fi
}

cleanup()
{
   echo "Clean up"

   CMD="rm $TESTFILE"
   echo "$CMD"
   $CMD
}

while [ -n "$1" ]; do
    case $1 in
        -h|--help ) usage ; exit 1 ;;
    esac
    shift
done

create_test_file
mount_card
write_sd_image
compare_test
umount_test
cleanup
sync

echo
if [ "$status_fail" == 0 ]; then
    echo "PASS"
else
    echo "FAIL due to failures already listed above"
fi

exit $status_fail
