#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <time.h> 
 
struct in_addr        localInterface;
struct sockaddr_in    groupSock;
int                   sd;
int                   datalen;
char *		      databuf;
 
// argv[0]   argv[1]    argv[2]    argv[3]  argv[4] argv[5]
// recvmc    localIP    mcastIP    portnu   secs
// sendmc    localIP    mcastIP    portnu   secs    msgsize
 
unsigned long long
getseconds(void)
{
	unsigned long long secs;
	struct timespec now;
	clock_gettime(CLOCK_MONOTONIC, &now);
	secs = now.tv_sec;
	return secs;
}
 
int main (int argc, char *argv[])
{
	int sd;
	int datalen;
	int portnu;
	int secs;
	unsigned long long starttime;
	int msgsize;

	if (argc < 6) {
		printf("Need at least 6 arguments - %s <localIP> <mcastIP> <portnu> <seconds> <msgsize>\n", 
			argv[0]);
		exit(1);
	}

	portnu = atoi(argv[3]);
	secs = atoi(argv[4]);
	msgsize = atoi(argv[5]);
	sd = socket(AF_INET, SOCK_DGRAM, 0);
	if (sd < 0) {
		perror("opening datagram socket");
		exit(1);
	}
 
	// Initialize the group sockaddr structure with a
	// group address of 225.1.1.1 and port 5555.
	memset((char *) &groupSock, 0, sizeof(groupSock));
	groupSock.sin_family = AF_INET;
	groupSock.sin_addr.s_addr = inet_addr(argv[2]);
	groupSock.sin_port = htons(portnu);
 
	// Disable loopback so you do not receive your own datagrams.
    	char loopch=0;
 
	if (setsockopt(sd, IPPROTO_IP, IP_MULTICAST_LOOP,
                   (char *)&loopch, sizeof(loopch)) < 0) {
 		perror("setting IP_MULTICAST_LOOP:");
		close(sd);
		exit(1);
	}
 
	// Set local interface for outbound multicast datagrams.
	// The IP address specified must be associated with a local,
	// multicast-capable interface.
	localInterface.s_addr = inet_addr(argv[1]);
	if (setsockopt(sd, IPPROTO_IP, IP_MULTICAST_IF,
                 (char *)&localInterface,
                 sizeof(localInterface)) < 0) {
		perror("setting local interface");
		exit(1);
	}
 
	databuf = (char *) malloc(msgsize + 16);
	if (databuf == NULL) {
		printf("databuf allocation failed!\n");	
		exit(1);
	}
	starttime = getseconds(); 
	// Send a message to the multicast group specified by the
	// groupSock sockaddr structure.
	do {
  		if (sendto(sd, databuf, msgsize, 0, (struct sockaddr*)&groupSock, sizeof(groupSock)) < 0) {
    			perror("sending datagram message");
			exit(1);
  		}
	} while ( ( getseconds() - starttime ) < secs ) ;
	close(sd);
	free(databuf);
}
