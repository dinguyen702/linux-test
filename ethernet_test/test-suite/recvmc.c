
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <errno.h>
#include <time.h> 
 
struct sockaddr_in    localSock;
struct ip_mreq        group;
char                  databuf[1024];

// argv[0]   argv[1]    argv[2]    argv[3]  argv[4]
// recvmc    localIP    mcastIP    portnu   seconds
// sendmc    localIP    mcastIP    portnu   seconds


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
	int starttime;

	if (argc < 5) {
		printf("Need at least 5 arguments - %s <localIP> <mcastIP> <portnu> <seconds>\n", 
			argv[0]);
		exit(1);
	}

	portnu = atoi(argv[3]);
	secs = atoi(argv[4]);

	sd = socket(AF_INET, SOCK_DGRAM, 0);
	if (sd < 0) {
		perror("opening datagram socket");
		exit(1);
	}
 
	// Enable SO_REUSEADDR to allow multiple instances of this
	// application to receive copies of the multicast datagrams.

	int reuse=1;
 
	if (setsockopt(sd, SOL_SOCKET, SO_REUSEADDR,
                   (char *)&reuse, sizeof(reuse)) < 0) {
		perror("setting SO_REUSEADDR");
		close(sd);
 		exit(1);
	}

	// Bind to the proper port number with the IP address
	// specified as INADDR_ANY.
	memset((char *) &localSock, 0, sizeof(localSock));
	localSock.sin_family = AF_INET;
	localSock.sin_port = htons(portnu);;
	localSock.sin_addr.s_addr  = INADDR_ANY;
 
	if (bind(sd, (struct sockaddr*)&localSock, sizeof(localSock))) {
		perror("binding datagram socket");
		close(sd);
 		exit(1);
	}
 
 
	// Join the multicast group 225.1.1.1 on the local 9.5.1.1
	// interface.  Note that this IP_ADD_MEMBERSHIP option must be
	// called for each local interface over which the multicast
	// datagrams are to be received.
	group.imr_multiaddr.s_addr = inet_addr(argv[2]);
	group.imr_interface.s_addr = inet_addr(argv[1]);
	if (setsockopt(sd, IPPROTO_IP, IP_ADD_MEMBERSHIP,
                 (char *)&group, sizeof(group)) < 0) {
		perror("adding multicast group");
		close(sd);
		exit(1);
	}

	int opt = 1;
	ioctl(sd, FIONBIO, &opt); 

	starttime = getseconds();
	datalen = sizeof(databuf);
	int bytesread;
	int totbytes=0;
	do {
		bytesread = read(sd, databuf, datalen);
		if ( (bytesread < 0) && (errno == EWOULDBLOCK)) {
			bytesread = 0;
		}
		totbytes += bytesread;
	} while ( (bytesread >= 0) && ( (getseconds()-starttime) < secs) ) ;

	close(sd);

	if (totbytes) {
		printf("%dbytes\n", totbytes); 
	} else {
		printf("none\n");
	}
}
