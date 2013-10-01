#!/bin/bash

# Start by initializing the CAN device.
canconfig can0 stop
# Set bitrate to 1M
canconfig can0 bitrate 1000000

canconfig can0 start

echo Start of CAN RX file >can_test_rx.txt

candump can0 >>can_test_rx.txt

echo Kernel Version 

echo End of file >>can_test_rx.txt

