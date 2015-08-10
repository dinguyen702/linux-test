include ../Makefile.inc

CFLAGS = -O0 -fno-omit-frame-pointer

EXE = memtool
OBJS = memtool.o
PKG = memtool.tar.gz
SRC = memtool.c Makefile
SCRIPTS =

all: $(EXE)
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) memtool.c -pthread -o memtool
	@file memtool

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
	-$(RM) -f $(OBJS) $(EXE) $(PKG)

release: clean
	tar czf $(PKG) $(SRC)
