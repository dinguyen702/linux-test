#!/bin/bash

dmesg -c
dmesg -n 3

insmod /lib/modules/3.7.0/kernel/drivers/dma/pl330.ko

insmod /lib/modules/3.7.0/kernel/drivers/dma/dmatest.ko

echo 10 >/sys/kernel/debug/dmatest/iterations

echo Y >/sys/kernel/debug/dmatest/run

sleep 5

# success_count=`grep -c "dma0chan[0-7].*0 failures" /var/log/messages`
success_count=`dmesg|grep -c "dma0chan[0-7].*0 failures"`

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
