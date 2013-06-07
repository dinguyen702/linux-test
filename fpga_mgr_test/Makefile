include ../Makefile.inc

FIRMWARE = *.rbf
SCRIPTS = *.sh

all :

install : $(SCRIPTS)
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 $(SCRIPTS) $(INSTALLPATH)
	$(INSTALL) -m644 $(FIRMWARE) $(INSTALLPATH)

clean :
