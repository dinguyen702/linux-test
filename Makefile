#               linux-test toplevel Makefile

# This is just a very simple Makefile that does 'make' commands
# in all the subdirectories that contain Makefiles

# Don't change this Makefile.  Instead, add your own.  See readme.txt.
# Also look at some of the other simple Makefiles in the subdirectories.

include Makefile.inc

# Directories that have a makefile only.
DIRS	= $(shell $(FIND) . -mindepth 2 -maxdepth 2 -depth -name Makefile -printf '%h\n')

INSTALLPATH ?= $(shell $(PWD))/unit_tests

all :
	@for subd in $(DIRS); do  \
	    $(ECHO);             \
	    $(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $$subd;   \
	done

install :
	$(INSTALL) -d $(INSTALLPATH)
	@for subd in $(DIRS); do                                  \
	    $(ECHO);                                              \
	    $(MAKE) -C $$subd INSTALLPATH=$(INSTALLPATH) install; \
	done

clean:
	@for subd in $(DIRS); do     \
	    $(ECHO);                 \
	    $(MAKE) -C $$subd clean; \
	done
