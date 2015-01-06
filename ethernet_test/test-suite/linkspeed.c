#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <linux/if_ether.h>
#include <net/if.h>
#include <netinet/in.h>
#include <net/if.h>
#include <linux/sockios.h>
#include <linux/ethtool.h>

void 
linkcheck(void)
{
	int s;
	struct ifreq ifr;
	if ((s = socket(PF_INET, SOCK_DGRAM, 0)) < 0) {
		printf("error\n");
		exit(1);
	}
	memset(&ifr, 0, sizeof(struct ifreq));
    	strncpy(ifr.ifr_name, "eth0", strlen("eth0"));

	int r;
	if ((r = ioctl(s, SIOCGIFFLAGS, &ifr)) == -1) {
		printf("ioctl fail %d, %d\n", r, errno);
		perror("linkcheck fail ");
	}
 	printf("linkstatus data %d %d\n", 
		ifr.ifr_flags & IFF_UP,
		ifr.ifr_flags & IFF_RUNNING);
	close(s);
}

void
linkstatus(void)
{
	int s;
	struct ifreq ifr;
	struct ethtool_value eth;
	if ((s = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ARP))) < 0) {
		printf("error\n");
		exit(1);
	}
	memset(&ifr, 0, sizeof(struct ifreq));
	memset(&eth, 0, sizeof(struct ethtool_value));
	eth.cmd = ETHTOOL_GLINK;
    	strcpy(ifr.ifr_name, "eth0");
    	ifr.ifr_data = (char *)&eth;

	int r;
	if ((r = ioctl(s, SIOCETHTOOL, &ifr)) == -1) {
		printf("ioctl fail %d, %d\n", r, errno);
		perror("ioctl fail ");
	 	u_int16_t *data = (u_int16_t *) &ifr.ifr_data;
		int ctl;
		data[0] = 0;

		if (ioctl(s, 0x8947, &ifr) >= 0)
			ctl = 0x8948;
		else if (ioctl(s, SIOCDEVPRIVATE, &ifr) >= 0)
			ctl = SIOCDEVPRIVATE + 1;
		else {
			close(s);
			printf("couldnt detect mii interface!\n");
		}

		data[1] = 1;
		if (ioctl(s, ctl, &ifr) >= 0) {
			int ret = !(data[3] & 0x4);
			printf("state %s\n", ret ? "dis" : "conn");
		}	
	}
 	printf("linkstatus data %d\n", eth.data);
	close(s);
}


int main (int argc, char **argv)
{
    int sock;
    struct ifreq ifr;
    struct ethtool_cmd edata;
    int rc;

    linkstatus();
    linkcheck();
    
    sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_IP);
    if (sock < 0) {
        perror("socket");
        exit(1);
    }

    strncpy(ifr.ifr_name, "eth0", sizeof(ifr.ifr_name));
    ifr.ifr_data = (caddr_t)&edata;

    edata.cmd = ETHTOOL_GSET;

    rc = ioctl(sock, SIOCETHTOOL, &ifr);
    if (rc < 0) {
        perror("ioctl");
        exit(1);
    }
    switch (edata.speed) {
        case SPEED_10: printf("10\n"); break;
        case SPEED_100: printf("100\n"); break;
        case SPEED_1000: printf("1000\n"); break;
        case SPEED_2500: printf("2500\n"); break;
        case SPEED_10000: printf("10000\n"); break;
        default: printf("Speed returned is %d\n", edata.speed);
    }
    return (0);
}
