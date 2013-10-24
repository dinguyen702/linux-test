cd linux-socfpga
make -j12 zImage
make dtbs
cp /home/vince/linux-socfpga/arch/arm/boot/zImage /tftpboot/zImage
cp /home/vince/linux-socfpga/arch/arm/boot/dts/socfpga_cyclone5.dtb /tftpboot/socfpga_cyclone5.dtb
ls -latr /tftpboot
cd /home/vince
