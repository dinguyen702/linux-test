UBOOTDIR = /home/vince/repos/u-boot-socfpga
BINNAME = uboot-test
LOADADDR = 0x0

## This can be cleaned up, it's functional for now - Vince

CFLAGS = -g -Os -fno-common -ffixed-r8 -msoft-float -nostdinc -march=armv7-a -mabi=aapcs-linux -pipe -mthumb
CFLAGS += -fno-builtin -ffreestanding
CFLAGS += -isystem /opt/gcc-linaro-arm-linux-gnueabihf-4.8-2013.10_linux/bin/../lib/gcc/arm-linux-gnueabihf/4.8.2/include
CFLAGS += -mthumb-interwork

CFLAGS +=-I$(UBOOTDIR)/include
CFLAGS +=-I..

CFLAGS += -D__ARM__
CFLAGS += -DCONFIG_ARM
CFLAGS += -D__KERNEL__

BIN = uboot-test.bin
OBJS = uboot-test.o crtinit.o startup.o
SRC = uboot-test.c crtinit.o startup.o Makefile
PKG = uboot-test.tar.gz
HEADERS = arm.h

CC = $(CROSS_COMPILE)gcc
OBJCOPY = ${CROSS_COMPILE}objcopy
NM = $(CROSS_COMPILE)nm
OBJDUMP = $(CROSS_COMPILE)objdump

all: $(BINNAME).bin

startup.o: startup.S
	$(CC) $(CFLAGS) -c -D__ASSEMBLEY__ startup.S
	@file startup.o

crtinit.o: crtinit.c $(HEADERS)
	$(CC) $(CFLAGS) -c crtinit.c
	@file crtinit.o

$(BINNAME).o: $(BINNAME).c $(HEADERS)
	$(CC) $(CFLAGS) -c $(BINNAME).c
	@file $(BINNAME).o

uboot-test: uboot-test.o crtinit.o startup.o
	$(CC) -nostdlib -o uboot-test startup.o crtinit.o uboot-test.o -Wl,-N,--build-id=none,-Ttext=$(LOADADDR)
	@file uboot-test

uboot-test.bin: uboot-test
	$(OBJCOPY) -O binary uboot-test uboot-test.bin 
	$(NM) uboot-test > uboot-test.map
	$(OBJDUMP) -S -d --prefix-addresses uboot-test > uboot-test.txt

install: uboot-test.bin
	cp uboot-test.bin /tftpboot/.
clean:
	-$(RM) $(OBJS) $(BIN) uboot-test uboot-test.map uboot-test.txt

release: clean
	tar czf $(PKG) $(SRC)
