#!/bin/bash
#i2c_test.sh

# this file was designed to run with the i2cdump tool to test the i2c connection
# on the socfpga5xs1 characterization board with the LEDs and the MAX7318AUG i/0 expansion part

#usage i2c_test
# you need to make sure that the i2c device is plugged in.

i2cdetect -l
// -f is for force -y is for not interactive (take this out to debug) 0x40 address of i/0 expansion part, b - byte write, 7a is the bank on the cyclone V
//reads this address
i2cdump -f -y 0x40 b 7A
//writes this address, 0x0f is the bit mask to set the first 4 bits.
i2cset -f -y 0x40 b 0x0f
echo "check to see that the USER_LEDs_HPs0-s3 are lit. \n"
sleep 5s
i2cset -f -y 0x40 b 0x00
echo "check to see that the same LEDs are off. \n"
sleep 5s
i2cset -f -y 0x40 b 0x01
echo "check to see that the USER_LEDs-HPs0 is on and all other 3 LEDS are off.\n"
echo "theeee endddddd\n"
