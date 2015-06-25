include ../Makefile.inc

all : memtester/memtester

memtester/memtester :
	echo "SKIPPING MEMTESTER"

install : memory-test.sh memtester/memtester
	$(INSTALL) -d $(INSTALLPATH)
	$(INSTALL) -m755 memory-test.sh $(INSTALLPATH)
	$(INSTALL) -m755 memtester/memtester $(INSTALLPATH)

clean :
	$(MAKE) -C memtester clean
