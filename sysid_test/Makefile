include ../Makefile.inc

PATCHES = *.patch
FPGA_IMAGES = *.rbf
SCRIPTS = *.sh

all :

install : $(SCRIPTS)
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 $(SCRIPTS) $(INSTALLPATH)
	$(INSTALL) -m644 $(PATCHES) $(INSTALLPATH)
	$(INSTALL) -m644 $(FPGA_IMAGES) $(INSTALLPATH)

clean :
