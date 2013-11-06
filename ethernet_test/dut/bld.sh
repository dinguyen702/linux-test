
echo "cross compiling ..."
/opt/gcc-linaro-arm-linux-gnueabihf-4.7-2012.11-20121123_linux/bin/arm-linux-gnueabihf-g++ -o duttest duttest.cpp 

echo "native machine compile ..."
g++ -o x86test duttest.cpp 

echo "scp file to dut"
scp duttest root@192.178.1.2:/home/root/duttest 
