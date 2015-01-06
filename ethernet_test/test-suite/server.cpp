#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <time.h> 


// -l -- bind to local interface (required)
// -u -- udp mode (tcp is default)
// -b -- receive buffer size (64K is default)
// -m -- multicast address to listen for (can be multiple options)
// -p -- port number
// -a -- affinity
// -x -- priority
// -t -- transmit thread
// -r -- receive thread
// -s -- stats
// -T -- touch all the data
// -e -- echo each message to recvfrom address
// -R -- relay each message to IP in recieved data
// -6 -- IPv6
// -u -- if echo, dont use udp checksum
// -n -- if echo, disable nagling
//
// returns bytes received, calls to recv, recvd/bytes per sec
//

// -s -t l=127.0.0.1,u,b=25000,m=224.0.0.1:34,m=224.0.0.1:35,a=0,x=2,T,e,R,u,n


int main(int argc, char *argv[])
{
    int listenfd = 0, connfd = 0;
    struct sockaddr_in serv_addr; 

    char sendBuff[1025];
    time_t ticks; 

    listenfd = socket(AF_INET, SOCK_STREAM, 0);
    memset(&serv_addr, '0', sizeof(serv_addr));
    memset(sendBuff, '0', sizeof(sendBuff)); 

    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port = htons(5000); 

    bind(listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)); 

    listen(listenfd, 10); 

    while(1)
    {
        connfd = accept(listenfd, (struct sockaddr*)NULL, NULL); 

        ticks = time(NULL);
        snprintf(sendBuff, sizeof(sendBuff), "%.24s\r\n", ctime(&ticks));
        write(connfd, sendBuff, strlen(sendBuff)); 

        close(connfd);
        sleep(1);
     }
}
