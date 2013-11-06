/opt/gcc-linaro-arm-linux-gnueabihf-4.7-2012.11-20121123_linux/bin/arm-linux-gnueabihf-g++ -o latency latency.cpp -lpthread -lrt -std=c++11
##scp ./latency root@192.178.1.2:/home/root/latency

g++ -std=c++0x -o latency latency.cpp -lpthread -lrt

