#!/bin/bash

flash_erase /dev/mtd0 0 0

filename=u-boot-spl-header.bin
rm $filename
wget http://137.57.160.198/linux_team_sd_images/qspi-boot-files/$filename
filesize=$(ls -l $filename |awk -F" " '{ print $5 }')
echo filesize of $filename is $filesize
mtd_debug write /dev/mtd0 0 $filesize $filename

filename=socfpga_cyclone5_socdk.dtb
rm $filename
wget http://137.57.160.198/nightly_build/latest-cyclone5-angstrom-v2013.12/binaries/$filename
filesize=$(ls -l $filename |awk -F" " '{ print $5 }')
echo filesize of $filename is $filesize
mtd_debug write /dev/mtd0 0x50000 $filesize $filename

filename=u-boot.img
rm $filename
wget http://137.57.160.198/linux_team_sd_images/qspi-boot-files/$filename
filesize=$(ls -l $filename |awk -F" " '{ print $5 }')
echo filesize of $filename is $filesize
mtd_debug write /dev/mtd0 0x60000 $filesize $filename

filename=zImage
rm $filename
wget http://137.57.160.198/nightly_build/latest-cyclone5-angstrom-v2013.12/binaries/$filename
filesize=$(ls -l $filename |awk -F" " '{ print $5 }')
echo filesize of $filename is $filesize
mtd_debug write /dev/mtd0 0xA0000 $filesize $filename

status=0
exit $status

