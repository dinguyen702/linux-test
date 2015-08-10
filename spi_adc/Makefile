# Copyright Altera 2013
# All Rights Reserved.
#
include ../Makefile.inc

C_SRC := spi-adc-test.c LTC2422.c
CFLAGS := -g -O0 -Werror -Wall
#OBJS = spi-adc-test.o LTC2422.o
LDFLAGS := -lm

#CROSS_COMPILE := arm-linux-gnueabihf-
CC := $(CROSS_COMPILE)gcc
NM := $(CROSS_COMPILE)nm

ifeq ($(or $(COMSPEC),$(ComSpec)),)
RM := rm -rf
else
RM := cs-rm -rf
endif

ELF ?= spi-adc-test
OBJ := $(patsubst %.c,%.o,$(C_SRC))

.c.o:
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c $< -o $@

.PHONY: all
all: $(ELF)

.PHONY:
clean:
	$(RM) $(ELF) $(OBJ) *.map *.objdump

$(ELF): $(OBJ) $(OBJS)
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) $(OBJ) -o $@ $(LDFLAGS)
	$(NM) $@ > $@.map

LTC2422.c: LTC2422.h
spi-adc-test.c: LTC2422.c LTC2422.h 

