include ../../Makefile.inc

EXE = rttest 
OBJS = rttest.o
PKG = rttest.tar.gz
SRC = rttest.cpp Makefile
SCRIPTS =

all: rttest

rttest: rttest.cpp 
	$(CXX) $(EXTRA_CFLAGS) -Wall rttest.cpp -o rttest -lrt 
	@file rttest

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
