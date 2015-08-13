nclude ../Makefile.inc

EXE = 
SCRIPTS = *.sh

all:

install: $(SCRIPTS) $(EXE)
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 $? $(INSTALLPATH)

clean:
