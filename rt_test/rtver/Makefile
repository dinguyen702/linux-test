include ../../Makefile.inc

EXE = rtver 
OBJS = rtver.o
PKG = rtver.tar.gz
SRC = rtver.cpp Makefile
SCRIPTS =

all: rtver

rtver: rtver.cpp 
	$(CXX) -Wall -fpermissive rtver.cpp -o rtver  
	@file rtver

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
