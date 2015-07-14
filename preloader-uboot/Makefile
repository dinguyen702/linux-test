include ../Makefile.inc

all : uboot-scripts/ping-test.img uboot-scripts/tftp-test.img sdram-test/sdram-test.bin tftp-test/tftp-test.bin

uboot-scripts/ping-test.img :
	$(CD) uboot-scripts && \
	make all

uboot-scripts/tftp-test.img :
	$(CD) uboot-scripts && \
	make all

sdram-test/sdram-test.bin : 
	$(if $(shell ls sdram-test/exclude),,$(CD) sdram-test && \
	make all)

tftp-test/tftp-test.bin : 
	$(if $(shell ls tftp-test/exclude),,$(CD) tftp-test && \
	make all)

clean :
	$(CD) uboot-scripts && make clean
	$(CD) sdram-test && make clean
