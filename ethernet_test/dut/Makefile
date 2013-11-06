include ../../Makefile.inc

EXE = duttest 
OBJS = duttest.o
PKG = duttest.tar.gz
SRC = duttest.cpp Makefile
SCRIPTS =

all: $(EXE)
	$(CXX) -o $(EXE) duttest.cpp 
	@file ping

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
