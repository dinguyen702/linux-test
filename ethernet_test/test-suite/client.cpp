#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <arpa/inet.h>
#include <getopt.h> 

// ipv4, ipv6 is implicit by the address specified
// 192.168.1.2@5645
// ::3@5645
//
// -l -- local interface to bind to
// -u -- udp mode (tcp mode default)
// -m -- message size
// -i -- ip address to use - could be broadcast or multicast
// -p -- port number
// -a -- affinity
// -x -- priority
// -t -- thread
// -n -- set no delay option (nagling), tcp only
// -u -- no udp checksum, udp only
// -s -- stats
// -T -- touch all the data
// -L -- ttl (64 is default)
// -S -- seconds to send (1 second default)
// -L -- collect round trip latency stats (only if
//       server is setup to echo)
//

// -S 10 -s -tu,T,x=1,a=2,l=192.178.1.2,m=3456,p=4567,n  

class clientThreadInfo {
public:
	bool nodelay;		// true by default
	bool udpchecksum;	// true by default
	bool touchdata;		// false by default
	bool udp;		// false by default
	struct sockaddr_in lip; // local ip to use
	struct sockaddr_in oip; // destination ip
	u16_t	port;
	int	affinity;	// -1 by default
	int	priority;	// -1 by default
	int	msgsize;	// 1 by default
	int	ttl;		// 64 by default
	int	seconds;	// 1 by default
    	clientThreadInfo() {}
};



int
client()
{

}




int main(int argc, char *argv[])
{
    int sockfd = 0, n = 0;
    char recvBuff[1024];
    struct sockaddr_in serv_addr; 

    if(argc != 2)
    {
        printf("\n Usage: %s <ip of server> \n",argv[0]);
        return 1;
    } 

    memset(recvBuff, '0',sizeof(recvBuff));
    if((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        printf("\n Error : Could not create socket \n");
        return 1;
    } 

    memset(&serv_addr, '0', sizeof(serv_addr)); 

    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(5000); 

    if(inet_pton(AF_INET, argv[1], &serv_addr.sin_addr)<=0)
    {
        printf("\n inet_pton error occured\n");
        return 1;
    } 

    if( connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
    {
       printf("\n Error : Connect Failed \n");
       return 1;
    } 

    while ( (n = read(sockfd, recvBuff, sizeof(recvBuff)-1)) > 0)
    {
        recvBuff[n] = 0;
        if(fputs(recvBuff, stdout) == EOF)
        {
            printf("\n Error : Fputs error\n");
        }
    } 

    if(n < 0)
    {
        printf("\n Read error \n");
    } 

    return 0;
}
