include ../Makefile.inc

all : ethtool/ethtool vlan/vconfig ping/ping dut/duttest sockperf/src/sockperf

#
# netperf build is very dirty, that requires some work. Leaving the steps
# below for reference for manaul building until the kinks
# get worked out
#
#netperf-2.6.0/src/netperf :
#	$(CD) netperf-2.6.0 && echo "ac_cv_func_setpgrp_void=yes" > config.cache
#	$(CD) netperf-2.6.0 && ./configure CC=${CROSS_COMPILE}gcc LD=${CROSS_COMPILE}ld --host=i386 --config-cache
#	$(CD) netperf-2.6.0 && make

sockperf/src/sockperf :
	$(CD) sockperf && ./autogen.sh
	$(CD) sockperf && ./configure CXX=${CROSS_COMPILE}g++ STRIP=${CROSS_COMPILE}strip LD=${CROSS_COMPILE}ld CC=${CROSS_COMPILE}gcc --host=i386
	rm -f sockperf/src/sockperf
	$(CD) sockperf && make
	## next few lines build x86, need to figure out how to take care of that
	#$(CD) sockperf && ./configure
	#$(CD) sockperf && make

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
