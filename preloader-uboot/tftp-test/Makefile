UBOOTDIR = /home/vince/repos/u-boot-socfpga
UBOOTLIB = ../uboot-lib
UBOOTAPI = ../uboot-api
TESTLIB = ../test-lib
TESTNAME = tftp
BINNAME = $(TESTNAME)-test
LOADADDR = 0x0

## This can be cleaned up, it's functional for now - Vince

CFLAGS = -g -Os -fno-common -ffixed-r8 -msoft-float -nostdinc -march=armv7-a -mabi=aapcs-linux -pipe -mthumb
CFLAGS += -fno-builtin -ffreestanding
CFLAGS += -isystem /opt/gcc-linaro-arm-linux-gnueabihf-4.8-2013.10_linux/bin/../lib/gcc/arm-linux-gnueabihf/4.8.2/include
CFLAGS += -mthumb-interwork

CFLAGS +=-I$(UBOOTDIR)/include
CFLAGS +=-I..
CFLAGS +=-I$(UBOOTLIB)
CFLAGS +=-I$(TESTLIB)

CFLAGS += -D__ARM__
CFLAGS += -DCONFIG_ARM
CFLAGS += -D__KERNEL__

BIN = $(TESTNAME)-test.bin
OBJS = $(TESTNAME)-test.o crtinit.o startup.o myrand.o 
SRC = $(TESTNAME)-test.c crtinit.o startup.o Makefile
HEADERS = $(UBOOTLIB)/arm.h $(TESTLIB)/myrand.h

CC = $(CROSS_COMPILE)gcc
OBJCOPY = ${CROSS_COMPILE}objcopy
NM = $(CROSS_COMPILE)nm
OBJDUMP = $(CROSS_COMPILE)objdump

all: $(BINNAME).bin

startup.o: $(UBOOTLIB)/startup.S
	$(CC) $(CFLAGS) -c -D__ASSEMBLEY__ $(UBOOTLIB)/startup.S
	@file startup.o

crtinit.o: $(UBOOTAPI)/crtinit.c $(HEADERS)
	$(CC) $(CFLAGS) -c $(UBOOTAPI)/crtinit.c
	@file crtinit.o

myrand.o: $(TESTLIB)/myrand.c $(HEADERS)
	$(CC) $(CFLAGS) -c $(TESTLIB)/myrand.c
	@file myrand.o

$(BINNAME).o: $(BINNAME).c $(HEADERS)
	$(CC) $(CFLAGS) -c $(BINNAME).c
	@file $(BINNAME).o

$(TESTNAME)-test: $(TESTNAME)-test.o crtinit.o startup.o myrand.o 
	$(CC) -nostdlib -o $(TESTNAME)-test startup.o crtinit.o myrand.o $(TESTNAME)-test.o -Wl,-N,--build-id=none,-Ttext=$(LOADADDR)
	@file $(TESTNAME)-test

$(TESTNAME)-test.bin: $(TESTNAME)-test
	$(OBJCOPY) -O binary $(TESTNAME)-test $(TESTNAME)-test.bin 
	$(NM) $(TESTNAME)-test > $(TESTNAME)-test.map
	$(OBJDUMP) -S -d --prefix-addresses $(TESTNAME)-test > $(TESTNAME)-test.txt

install: $(TESTNAME)-test.bin
	cp $(TESTNAME)-test.bin /tftpboot/.

clean:
	-$(RM) $(OBJS) $(BIN) $(TESTNAME)-test $(TESTNAME)-test.map $(TESTNAME)-test.txt

