include ../Makefile.inc

DATAFILES = qspi-data-file
SCRIPTS = *.sh

all :

install : $(SCRIPTS) $(EXE)
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 $? $(INSTALLPATH)
	$(INSTALL) -m644 $(DATAFILES) $(INSTALLPATH)

clean :
