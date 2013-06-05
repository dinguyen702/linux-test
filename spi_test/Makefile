include ../Makefile.inc

SCRIPTS = *.sh
EXE = spidev-test
OBJS = spidev-test.o

all : $(EXE)

install : $(SCRIPTS) $(EXE)
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 $? $(INSTALLPATH)

clean :
	-$(RM) $(OBJS) $(EXE)

spidev-test.o : spidev-test.c
	$(CC) -c -Wall -Wextra spidev-test.c
