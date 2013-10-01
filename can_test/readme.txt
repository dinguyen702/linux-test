Either use the archived tools for this test or build the tools as described in Building Your Own below.

If using the archived tools, copy the files as described in the Install on Linux Filesystem section below.



Building Your Own:

download the can-utils  from:
http://www.pengutronix.de/software/socket-can/download/canutils/v4.0/canutils-4.0.6.tar.bz2

and the libsocket library from;
http://www.pengutronix.de/software/libsocketcan/download/libsocketcan-0.0.9.tar.bz2

Building the files:

Libsocket library porting:
execute the following instructions.
1) export PATH=/opt/altera-linux/gcc-linaro-arm-linux-gnueabihg-4.7-2012.11-20121123_linux/bin/:$PATH
2) tar xfj libsocketcan-0.0.9.tar.bz2
3) ./configure --host=arm-linux-gnueabihf --prefix=$PWD/__install
4) make
5) make install

The generated library can be found under the __install/ directory.

Can-Utils Cross Compiling:
execute the following instructions:
1) tar canutils-4.0.6.tar.bz2
2) ./configure --host=arm-linux-gnueabihf --prefix=$PWD/__install \
      libsocketcan_LIBS=-lsocketcan LDFLAGS=-L$PWD/../libsocketcan-0.0.9/__install/lib \
      libsocketcan_CFLAGS=-I$PWD/../libsocketcan-0.0.9/__install/include \
      CFLAGS=-I$PWD/../libsocketcan-0.0.9/__install/include
3) make
4) make install



Install on Altera Linux Filesystem.

Copy the can utilities (canconfig, cansend, candump) to the /bin directory so they can be executed on the platform.

Copy libsocketcan (libsocketcan.so.2.2.0 & create simlinks) to /lib on SD card. In /lib of SD card:
sudo ln -s libsocketcan.so.2.2.0 libsocketcan.so
sudo ln -s libsocketcan.so.2.2.0 libsocketcan.so.2

Resulting files

libsocket
lrwxrwxrwx    1 root    root   21 Feb 27 18:55 /lib/libsocketcan.so -> libsocketcan.so.2.2.0
lrwxrwxrwx    1 root    root   21 Feb 27 18:55 /lib/libsocketcan.so.2 -> libsocketcan.so.2.2.0
lrwxrwxrwx    1 root    root   12007 Feb 27 18:55 /lib/libsocketcan.so.2.2.0

canutils
-rwxrwxrwx    1 root    root   38437 Feb 27 18:55 /bin/canconfig
-rwxrwxrwx    1 root    root   20706 Feb 27 2013  /bin/candump
-rwxrwxrwx    1 root    root   17763 Feb 27 2013  /bin/cansend


