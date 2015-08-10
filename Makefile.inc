CC	= $(CROSS_COMPILE)gcc
CXX	= $(CROSS_COMPILE)g++
STRIP	= $(CROSS_COMPILE)strip
LD	= $(CROSS_COMPILE)ld
CD	= cd
CP	= cp
ECHO	= echo
FIND	= find
INSTALL = install
LS	= ls
PWD	= pwd
RM	= rm
SHELL	= /bin/bash
EXTRA_CFLAGS =  -march=armv7-a -mfloat-abi=hard -mfpu=neon
