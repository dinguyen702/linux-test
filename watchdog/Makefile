include ../Makefile.inc

CFLAGS = -O0 -fno-omit-frame-pointer

EXE = watchdog-test
OBJS = watchdog-test.o
PKG = watchdog-test.tar.gz
SRC = watchdog-test.c Makefile
SCRIPTS =

all: $(EXE)
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) watchdog-test.c -pthread -o watchdog-test
	@file watchdog-test

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
