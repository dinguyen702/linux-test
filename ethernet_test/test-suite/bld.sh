
g++ -std=c++03 -Wall -O4 options.cpp -lpthread -lrt

## Global options
## -S10 -- seconds to run, 0 for infinite (default for receive thread)
## -r -- receive thread
## -llocalhost@5000 -- ip address and port number
## -t --transmit thread
## -llocalhost -- local interface to bind to
## -ilocalhost@5000 -- ip address to open and send to
## -m2 -- message size
## 
./options -S10 -r -llocalhost@5000 -t -llocalhost -ilocalhost@5000 -m2 
