#!/bin/bash

trap ctrl_c INT
function ctrl_c() {
	echo "** Trapped CTRL-C"
	exit
}
ifconfig eth0 down
ifconfig eth0 mtu $1 up
ifconfig eth0


ifconfig eth0.100 down
ifconfig eth0.100 mtu $1 up
ifconfig eth0.100 192.188.1.1 netmask 255.255.255.0
ifconfig eth0.100

sleep 10
./myping -M -s 1000 -c 5 $2 
./myping -M -s 2000 -c 5 $2
./myping -M -s 4000 -c 5 $2
./myping -M -s 5000 -c 5 $2

for (( pkts=1468; pkts<=1476; pkts++ ))
do
	./myping -M -s $pkts -c 5 $2
done

for (( pkts = 2000; pkts<=2010; ++pkts ))
do
	./myping -M -s $pkts -c 5 $2
done

for (( pkts = 4036; pkts<=4046; ++pkts )) 
do
	./myping -M -s $pkts -c 5 $2
done


./myping -M -s 5000 -c 5 $2




