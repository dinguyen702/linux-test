gcc -o rawsend rawsend.c -lrt 
${CROSS_COMPILE}gcc -o rawrecv rawrecv.c -lrt
scp rawrecv root@192.199.1.2:/home/root/rawrecv
./emactestpromis.exp
