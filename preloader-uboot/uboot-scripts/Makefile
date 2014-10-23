
MKIMAGE = mkimage -T script -C none -n 'UBoot test'

# clear out all suffixes
.SUFFIXES: 

# only define the ones we need for this build procedure
.SUFFIXES: .img .ubootscr

RESULTS = $(patsubst %.ubootscr,%.img,$(wildcard *.ubootscr))

all: $(RESULTS)

%.img: %.ubootscr
	 $(MKIMAGE) -d $? $@ 

install: all
	cp *.img /tftpboot/.

clean:
	rm -f *.img
	
