
MKIMAGE = mkimage -T script -C none -n 'UBoot test'

# clear out all suffixes
.SUFFIXES: 

# only define the ones we need for this build procedure
.SUFFIXES: .img .ubootscr

RESULTS = ping-test.img first-uboot-script.img

all: $(RESULTS)

ping-test.img: ping-test.ubootscr
	 $(MKIMAGE) -d $? $@ 

first-uboot-script.img: first-uboot-script.txt
	 $(MKIMAGE) -d $? $@

install: all
	cp *.img /tftpboot/.

clean:
	rm -f $(RESULTS)
	
