include ../Makefile.inc

all : ethtool/ethtool vlan/vconfig ping/ping dut/duttest

ethtool/ethtool :
	$(CD) ethtool && \
	./configure CC=${CROSS_COMPILE}gcc --host i386 && \
	$(MAKE)

vlan/vconfig :
	$(CD) vlan && \
	make -B vconfig	 CC=${CROSS_COMPILE}gcc STRIP=${CROSS_COMPILE}strip

ping/ping :
	$(CD) ping && \
	make -B ping

dut/duttest :
	$(CD) dut && \
	make -B duttest

install : ethtool/ethtool
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 ethtool/ethtool $(INSTALLPATH)

# ethtool's make clean isn't all that tidy
clean :
#	$(MAKE) -C ethtool clean
	$(CD) ethtool && \
	$(RM) -rf .deps && \
	$(RM) -f Makefile config.log config.status ethtool-config.h stamp-h1 ethtool *.o
