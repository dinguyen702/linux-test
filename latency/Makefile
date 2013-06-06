include ../Makefile.inc

CFLAGS = -O0 -fno-omit-frame-pointer

EXE = latency
OBJS = latency.o
PKG = latency.tar.gz
SRC = latency.c Makefile
SCRIPTS =

all:
	$(CC) $(CFLAGS) latency.c -pthread -o latency 
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
