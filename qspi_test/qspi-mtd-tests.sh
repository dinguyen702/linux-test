#!/bin/bash

if ! insmod spi-nor.ko
then
exit
fi

if ! insmod cadence-quadspi.ko
then
exit
fi

if ! insmod mtd_speedtest.ko dev=0
then 
exit
fi

if ! insmod mtd_readtest.ko dev=0
then
exit
fi

if ! insmod mtd_stresstest.ko dev=0
then
exit
fi

