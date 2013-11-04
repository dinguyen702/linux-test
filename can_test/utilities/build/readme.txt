Create a directory that will hold the canutil directory and the libsocket directory.

mkdir canutils

Download canutils and libsocket from pengutronix.de.
http://www.pengutronix.de/software/socket-can/download/canutils/v4.0/canutils-4.0.6.tar.bz2
http://www.pengutronix.de/software/libsocketcan/download/libsocketcan-0.0.9.tar.bz2

Place these int he directory that was created above (canutils).

Copy the scripts into this top level directory and run the libsocket script first.
The libsocket library is used by the canutils so it is a pre-requisite.

Run the canutils-build.sh script second.

The following can utility programs can be found in the canutils folder

/canutils/canutils-4.0.6/__install/bin
candump
cansend

/canutils/canutils-4.0.6/__install/sbin
canconfig

Copy these files into the /bin directory of the embedded Linux distribution.

--------------------------------------------------
Copy the libsocketcan libraries and the symbolic links to the 
/lib directory of the embedded Linux distribution.

/canutils/libsocketcan-0.0.9/__install/lib
libsocketcan.so -> libsocketcan.so.2.2.0
libsocketcan.so.2 -> libsocketcan.so.2.2.0
libsocketcan.so.2.2.0

There have been some minor changes to the canutilities. Two patch files
will apply the appropriate patches if needed to the 4.0.6 release.
