#!/bin/bash

BASE_URL=$1

cwd=$(pwd)
cd /
rm modules.tar
wget $BASE_URL/modules.tar
tar xf modules.tar

dmesg -C
dmesg -n 3

modprobe pl330
modprobe dmatest

echo 10 >/sys/module/dmatest/parameters/iterations

echo Y >/sys/module/dmatest/parameters/run

sleep 5

dmesg

echo "-----------------------------------------------------------"

# success_count=`grep -c "dma0chan[0-7].*0 failures" /var/log/messages`
success_count=`dmesg|grep -c "dma0chan[0-7].*0 failures"`

cd $cwd

echo Success count is $success_count
if [ $success_count = "8" ]
then
echo "PASS"
status=0
else
echo "FAIL"
status=1
fi
exit $status
