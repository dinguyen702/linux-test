
#ifconfig eth0 down
#ifconfig eth0 mtu 2000 up

start=64
end=3100
incr=64
affinity=0
ipaddr=192.188.1.2
tm=4

for (( msg = $start; msg <= $end; msg+=$incr)) 
do
	./sockperf tp -i $ipaddr -t $tm -m $msg --no-rdtsc --sender-affinity $affinity
done


for (( msg = $start; msg <= $end; msg+=$incr)) 
do 
	./sockperf tp -i $ipaddr -t $tm -m $msg --no-rdtsc --tcp --tcp-avoid-nodelay --sender-affinity $affinity
done

## 66560
for (( msg = 1024; msg < 65536; msg+=1024)) 
do
	./sockperf tp -i $ipaddr -t $tm -m $msg --no-rdtsc --tcp --tcp-avoid-nodelay --sender-affinity $affinity 
done
