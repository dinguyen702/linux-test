include ../../Makefile.inc

CFLAGS = -O0 -fno-omit-frame-pointer

EXE = calibrator 
OBJS = calibrator.o
PKG = calibrator.tar.gz
SRC = calibrator.c Makefile
SCRIPTS =

all:
	$(CC) $(CFLAGS) calibrator.c -lm -o calibrator
	@file calibrator

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
