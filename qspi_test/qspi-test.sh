#!/bin/bash

flash_erase /dev/mtd0 0 0
#flash_erase /dev/mtd1 0 0

echo Start of file >test.txt

var=10000000
while [ $var -lt 10125000 ]
do
   echo $var >>test.txt
   var=$(( $var + 1 ))
done

echo End of file >>test.txt

filesize=$(ls -l test.txt |awk -F" " '{ print $5 }')

echo filesize is $filesize

flashcp test.txt /dev/mtd0
mtd_debug read /dev/mtd0 0 $filesize test1.txt

thesame=$(diff -q test.txt test1.txt|grep differ)

if [ "$thesame" != "" ]
then
echo FAIL
status=1
else
echo PASS
status=0
fi
exit $status
