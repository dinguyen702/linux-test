rm -rf libsocketcan-0.0.9/
export PATH=/opt/altera-linux/linaro/gcc-linaro-arm-linux-gnueabihf-4.7-2012.11-20121123_linux/bin/:$PATH
tar xfj libsocketcan-0.0.9.tar.bz2
chmod -R 777 libscocketcan-0.0.9/
cd libsocketcan-0.0.9/
./configure --host=arm-linux-gnueabihf --prefix=$PWD/__install
make
make install

