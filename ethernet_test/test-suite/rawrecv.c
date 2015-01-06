#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <net/ethernet.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <errno.h>
#include <time.h> 
 

unsigned long long
getseconds(void)
{
	unsigned long long secs;
	struct timespec now;
	clock_gettime(CLOCK_MONOTONIC, &now);
	secs = now.tv_sec;
	return secs;
}
 
int raw_init(const char *device, int promis)
{
    struct ifreq ifr;
    int raw_socket;

    memset (&ifr, 0, sizeof (struct ifreq));

    /* Open A Raw Socket */
    if ((raw_socket = socket (PF_PACKET, SOCK_RAW, htons (ETH_P_ALL))) < 1)
    {
        printf ("ERROR: Could not open socket, Got #?\n");
        exit (1);
    }

    /* Set the device to use */
    strcpy (ifr.ifr_name, device);

    /* Get the current flags that the device might have */
    if (ioctl (raw_socket, SIOCGIFFLAGS, &ifr) == -1)
    {
        perror ("Error: Could not retrive the flags from the device.\n");
        exit (1);
    }

    if (promis) {
    	/* Set the old flags plus the IFF_PROMISC flag */
    	ifr.ifr_flags |= IFF_PROMISC;
    } else {
	ifr.ifr_flags &= ~IFF_PROMISC;
    }
    if (ioctl (raw_socket, SIOCSIFFLAGS, &ifr) == -1) {
        	perror ("Error: Could not set flag IFF_PROMISC");
        	exit (1);
    }
    
    /* Configure the device */

    if (ioctl (raw_socket, SIOCGIFINDEX, &ifr) < 0)
    {
        perror ("Error: Error getting the device index.\n");
        exit (1);
    }

    return raw_socket;
}

unsigned char recvbuf[4096];



//
// argv[0] progname argv[1] ethX argv[2] promis argv[3] <secs>
int main(int argc, char **argv)
{
	int sock = raw_init(argv[1], atoi(argv[2]) );
	int secs = atoi(argv[3]);
	int opt = 1;
	if ( ioctl(sock, FIONBIO, &opt) != 0) {
		printf("ioctl to set non-blocking mode failed %s\n", strerror(errno));
		exit(1);
	}

	int bytesread=0;
	int starttime;
	int totbytes=0;
	int debug=0;
	starttime = getseconds();
	do {
		bytesread = read(sock, recvbuf, 2048);
		if ( (bytesread < 0) && (errno == EWOULDBLOCK)) {
			bytesread = 0;
		}
		if ( (recvbuf[0] == 0x00) && (recvbuf[1] == 0xff) 
 		  && (recvbuf[2] == 0xee) && (recvbuf[3] == 0xdd)
 		  && (recvbuf[4] == 0xcc) && (recvbuf[5] == 0xbb)) {
			totbytes += bytesread;
		}
		totbytes += bytesread;
		if ( bytesread && debug) {
			printf("recvd %d bytes,  %02x-%02x-%02x-%02x-%02x-%02x %02x-%02x-%02x-%02x-%02x-%02x %02x-%02x\n", bytesread,
			   recvbuf[0], 
			   recvbuf[1], 
			   recvbuf[2], 
			   recvbuf[3], 
			   recvbuf[4], 
			   recvbuf[5],
			   recvbuf[6],
			   recvbuf[7],
			   recvbuf[8],
			   recvbuf[9],
			   recvbuf[10],
			   recvbuf[11],
			   recvbuf[12],
			   recvbuf[13]
			);
		}
	} while ( (bytesread >= 0) && ( (getseconds()-starttime) < secs) ) ;

	if (totbytes) {
		printf("%dbytes\n", totbytes); 
	} else {
		printf("none\n");
	}

	return 0;
}
