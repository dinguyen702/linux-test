

ethtool:
 * version is currently 3.6
 * to build:
    # ./configure CC=${CROSS_COMPILE}gcc --host i386
    # make

vlan 1.9, built like so, (currently in the top level Makefile in this
directory - this is for reference)
	rm -f vlan_1.9.orig.tar.gz
	rm -f vlan_1.9.orig.tar
	rm -rf vlan
	wget http://ftp.de.debian.org/debian/pool/main/v/vlan/vlan_1.9.orig.tar.gz
	gzip -d vlan_1.9.orig.tar.gz
	tar -xvf vlan_1.9.orig.tar
	cd vlan
	make -B vconfig
	CC=/opt/gcc-linaro-arm-linux-gnueabihf-4.7-2012.11-20121123_linux/bin/arm-linux-gnueabihf-gcc
		STRIP=/opt/gcc-linaro-arm-linux-gnueabihf-4.7-2012.11-20121123_linux/bin/arm-linux-gnueabihf-strip
		HOME=/home/vince/linux-socfpga/include



