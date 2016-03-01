include ../Makefile.inc

OVERLAYS = *.dtb.o
SCRIPTS = *.sh

all :

install : $(SCRIPTS)
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 $(SCRIPTS) $(INSTALLPATH)
	$(INSTALL) -m644 $(OVERLAYS) $(INSTALLPATH)

clean :
