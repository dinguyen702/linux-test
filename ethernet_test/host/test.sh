#!/usr/bin/expect -f
set timeout 20
spawn cu -l /dev/ttyUSB0 -s 57600 
expect "Connected" 
send "ifconfig\r" 
expect "eth0"
