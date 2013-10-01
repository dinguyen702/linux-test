#!/bin/bash

# Start by initializing the CAN device.
canconfig can0 stop
# Set bitrate to 1M
canconfig can0 bitrate 1000000

canconfig can0 start

echo Kernel Version 
echo Start of CAN file >can_test_tx.txt

cansend can0 -i 0x123 0x11 0x22 0x33 0x44 0x55 0x66 0x77 0x88
echo "cansend can0 -i 0x123 0x11 0x22 0x33 0x44 0x55 0x77 0x88" >>can_test_tx.txt
:
echo End of file >>can_test_tx.txt

