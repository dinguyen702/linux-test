#!/bin/bash

flash_erase /dev/mtd0 0 0

filename=qspi-data-file
filesize=$(ls -l $filename |awk -F" " '{ print $5 }')

echo filesize is $filesize

flashcp $filename /dev/mtd0
mtd_debug read /dev/mtd0 0 $filesize qspi-data-out

thesame=$(diff -q $filename qspi-data-out|grep differ)

if [ "$thesame" != "" ]
then
echo FAIL
status=1
else
echo PASS
status=0
fi
exit $status
