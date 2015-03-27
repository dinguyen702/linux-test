include ../Makefile.inc

BITSTREAMS = *.gz
SCRIPTS = *.sh

all :

install : $(SCRIPTS)
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 $(SCRIPTS) $(INSTALLPATH)
	$(INSTALL) -m644 $(BITSTREAMS) $(INSTALLPATH)

clean :
