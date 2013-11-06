include ../../Makefile.inc

EXE = ping 
OBJS = ping.o
PKG = ping.tar.gz
SRC = ping.c Makefile
SCRIPTS =

all: $(EXE)
	$(CC) -Wall -o $(EXE) ping.c 
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
