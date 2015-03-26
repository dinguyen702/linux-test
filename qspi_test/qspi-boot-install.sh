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

flash_erase -j /dev/mtd1 0 0
cd
filename=extended-console-image-socfpga_cyclone5.tar.gz
rm $filename
wget http://137.57.160.198/nightly_build/latest-cyclone5-angstrom-v2013.12/binaries/$filename
filesize=$(ls -l $filename |awk -F" " '{ print $5 }')
echo filesize of $filename is $filesize
mkdir /home/root/tmp
mount -t jffs2 /dev/mtdblock1 /home/root/tmp
long_filename=$(readlink -f $filename)
cd /home/root/tmp
tar xf $long_filename
cd 
umount /home/root/tmp

status=0
exit $status

