rm -rf canutils-4.0.6/
tar xfj canutils-4.0.6.tar.bz2
chmod -R 777 canutils-4.0.6
cd canutils-4.0.6
export PATH=/opt/altera-linux/linaro/gcc-linaro-arm-linux-gnueabihf-4.7-2012.11-20121123_linux/bin/:$PATH
./configure --host=arm-linux-gnueabihf --prefix=$PWD/__install \
libsocketcan_LIBS=-lsocketcan \
LDFLAGS=-L$PWD/../libsocketcan-0.0.9/__install/lib \
libsocketcan_CFLAGS=-I$PWD/../libsocketcan-0.0.9/__install/include \
CFLAGS=-I$PWD/../libsocketcan-0.0.9/__install/include
make 
make install

