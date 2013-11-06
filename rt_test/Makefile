include ../Makefile.inc

all : calibrator/calibrator latency/latency rttest/rttest rtver/rtver

calibrator/calibrator :
	$(CD) calibrator && \
	$(MAKE)

latency/latency :
	$(CD) latency && \
	$(MAKE)

rttest/rttest :
	$(CD) rttest && \
	$(MAKE)

rtver/rtver :
	$(CD) rtver && \
	$(MAKE)

install : calibrator/calibrator latency/latency rttest/rttest rtver/rtver

clean : calibrator/calibrator latency/latency rttest/rttest rtver/rtver
	$(RM) -f calibrator/calibrator
	$(RM) -f calibrator/*.o
	$(RM) -f latency/latency
	$(RM) -f latency/*.o
	$(RM) -f rttest/rttest
	$(RM) -f rttest/*.o
	$(RM) -f rtver/rtver
	$(RM) -f rtver/*.o
