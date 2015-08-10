include ../../Makefile.inc

EXE = latency 
OBJS = latency.o
PKG = latency.tar.gz
SRC = latency.cpp Makefile
SCRIPTS =

all: latency

latency: latency.cpp OnlineStats.h QuantileEstimator.h
	$(CXX) $(EXTRA_CFLAGS) -Wall latency.cpp -o latency -lpthread -lrt
	@file latency

install : $(SCRIPTS) $(EXE)
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 $? $(INSTALLPATH)

.PHONY : help
help:
	@echo "usage of this Makefile"
	@echo "make         : builds the application (same as 'make all')"
	@echo "make clean   : clean binaries"
	@echo "make release : makes a tar ball of these sources"
	@echo "make help    : this message"

clean:
	-$(RM) $(OBJS) $(EXE) $(PKG)

release: clean
	tar czf $(PKG) $(SRC)
