include ../Makefile.inc

CFLAGS = -O0 -fno-omit-frame-pointer

EXE = spi-test-loopback
OBJS = spi-test-loopback.o
PKG = spi-test-loopback.tar.gz
SRC = spi-test-loopback.c Makefile
SCRIPTS = *.sh

all: 
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) spi-test-loopback.c -pthread -o $(EXE)
	@file spi-test-loopback

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
