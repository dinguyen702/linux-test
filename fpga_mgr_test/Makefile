include ../Makefile.inc

OVERLAYS = *.dtb.o
FPGA_IMAGES = *.gz
SCRIPTS = *.sh

all :

install : $(SCRIPTS)
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 $(SCRIPTS) $(INSTALLPATH)
	$(INSTALL) -m644 $(OVERLAYS) $(INSTALLPATH)
	$(INSTALL) -m644 $(FPGA_IMAGES) $(INSTALLPATH)

clean :
