
#include <arpa/inet.h>
#include <net/ethernet.h>
#include <net/if.h>
#include <net/if_arp.h>
#include <netinet/in.h>
#include <netpacket/packet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <time.h> 

int initialize(char *device, int sd, int promisc) 
{
	struct ifreq ifr;
	
	strncpy(ifr.ifr_name, device, sizeof(ifr.ifr_name));
	if (ioctl(sd, SIOCGIFFLAGS, &ifr)<0) {
		perror("SIOCGIFFLAGS");
		return -1;
	}
	
	if (promisc)
		ifr.ifr_flags |= IFF_PROMISC;
	else
		ifr.ifr_flags &= ~IFF_PROMISC;
	
	if (ioctl(sd, SIOCSIFFLAGS, &ifr)<0) {
		perror("SIOCSIFFLAGS");
		return -1;
	}
	
	printf("Initialized device %s\n", device);
	
	if (ioctl(sd, SIOCGIFINDEX, &ifr)<0) {
		perror("SIOCGIFINDEX");
		return -1;
	}
	
	return ifr.ifr_ifindex;
}

unsigned long long
getseconds(void)
{
	unsigned long long secs;
	struct timespec now;
	clock_gettime(CLOCK_MONOTONIC, &now);
	secs = now.tv_sec;
	return secs;
}
void printMAC(u_char *mac) 
{
	int i;
	printf("%.2x", mac[0]);
	for (i = 1; i < ETH_ALEN; i++) {
		printf(":%.2x", mac[i]);
	}
}

u_char frame[2048];

int main(int argc, char **argv) 
{
	const u_char startMAC[8] = {0x00, 0x09, 0xBF, 0x0B, 0x79, 0xB0, 0, 0};
	struct ethhdr *ethHeader;
	struct sockaddr_ll etherSocket;
	int sd;
	int ethIndex;
	int header_offset = 0;

	frame[0] = 0;
	frame[1] = 0xff;
	frame[2] = 0xee;
	frame[3] = 0xdd;
	frame[4] = 0xcc;
	frame[5] = 0xbb;

	frame[6] = 0x4;
	frame[7] = 0x4;
	frame[8] = 0x4;
	frame[9] = 0x4;
	frame[10] = 0x4;
	frame[11] = 0x4;

	frame[12] = 0x08;
	frame[13] = 0x70;
	
	// Set up raw sockets for sending
	sd = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
	if (sd < 0) {
		printf("Couldn't create packet socket :(\n");
		return 1;
	}

	if ((ethIndex = initialize(argv[1], sd, 1)) < 0) {
		printf("Couldn't find adapter.\n");
		return 1;
	}
	int secs = atoi(argv[2]);

/*	// Set the MAC address to our starting one
	struct ifreq req;
	strcpy(req.ifr_name, "ath0");
	req.ifr_hwaddr.sa_family = ARPHRD_ETHER;
	memcpy(req.ifr_hwaddr.sa_data, startMAC, 6);		
	
	if (ioctl(sd, SIOCSIFHWADDR, &req) < 0) {
		printf("Unable to set MAC address %d.\n",errno);
		return 1;
	}*/

	// Bind the socket to the interface
	memset(&etherSocket, 0, sizeof(etherSocket));
	etherSocket.sll_family = AF_PACKET;
	etherSocket.sll_protocol = htons(ETH_P_ALL);
	etherSocket.sll_ifindex = ethIndex;

	if (bind(sd, (struct sockaddr *)&etherSocket, sizeof(etherSocket)) <
0) {
		printf("Couldn't bind socket.\n");
		return 1;
	}

	memset(&etherSocket, 0, sizeof(etherSocket));
	etherSocket.sll_family = AF_PACKET;
	etherSocket.sll_ifindex = ethIndex;
	memcpy(etherSocket.sll_addr, startMAC, 8);
	etherSocket.sll_halen = 6;

	int starttime = getseconds();
	do {
		if (sendto(sd, frame + header_offset, 
            		512, 0, (struct sockaddr *)&etherSocket, sizeof(etherSocket)) ==
	    		-1) {

			printf("Error in sending packet.\n");
			return 1;
		}
	
	} while (  (getseconds()-starttime) < secs ) ;

	return 0;
}
