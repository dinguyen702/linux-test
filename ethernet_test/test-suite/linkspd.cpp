#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <string>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <linux/if_ether.h>
#include <net/if.h>
#include <netinet/in.h>
#include <net/if.h>
#include <linux/sockios.h>
#include <linux/ethtool.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <unistd.h>

// SIOCGIFHWADDR - mac address
// SIOCGIFMETRIC - ??
// SIOCGIFMTU    - device MTU
// duplex?
// Pause information?

class ethxinfo {
private:
	std::string		strif;
	int			sock;
	struct ifreq		ifr;
	struct ethtool_value 	eth;
	struct ethtool_cmd	ethcmd;

	void
	initifr(void)
	{
		memset((caddr_t)&ifr, 0, sizeof(struct ifreq));
		strcpy(ifr.ifr_name, strif.c_str());
	}
public:
	ethxinfo(std::string intf)
	{
		strif = intf;
		if ((sock = socket(PF_INET, SOCK_DGRAM, 0)) < 0) {
			printf("error\n");
			exit(1);
		}
	}

	int
	linkstatus(void)
	{
		int rc;
		initifr();
		if ((rc = ioctl(sock, SIOCGIFFLAGS, &ifr)) == -1) {
			perror("linkstatus ioctl");
			return -1;
		}

		int link = 0;
		if ((ifr.ifr_flags & IFF_UP) &&
		    (ifr.ifr_flags & IFF_RUNNING)) {
			link = 1;
		}
 		//printf("linkstatus data %d %d\n", 
		//	ifr.ifr_flags & IFF_UP,
		//	ifr.ifr_flags & IFF_RUNNING);
		return link;
	}

	int 
	linkspeed(void)
	{
		initifr();
		memset((void *)&ethcmd, 0, sizeof(struct ethtool_cmd));
		ethcmd.cmd = ETHTOOL_GSET;
		ifr.ifr_data = (caddr_t) &ethcmd;
		int rc = ioctl(sock, SIOCETHTOOL, &ifr);
		if (rc < 0) {
			perror("linkspeed ioctl");
			return -1;
		}
		switch (ethcmd.speed) {
			case SPEED_10: return 10; break;
			case SPEED_100: return 100; break;
			case SPEED_1000: return 1000; break;
			case SPEED_2500: return 2500; break;
			case SPEED_10000: return 10000; break;
			default: return -1; break;
		}
		return -1;
	}

	int
	mtu(void)
	{
		int rc;
		initifr();
		if ((rc = ioctl(sock, SIOCGIFMTU, &ifr)) == -1) {
			perror("mtu ioctl");
			return -1;
		}
		printf("%d\n", ifr.ifr_mtu);
		return ifr.ifr_mtu;

	}
	
	std::string
	ipv4addr(void)
	{
		int rc;
		initifr();
		ifr.ifr_addr.sa_family = AF_INET;
		if ((rc = ioctl(sock, SIOCGIFADDR, &ifr)) == -1) {
			perror("ipv4 ioctl");
			return "(none)";
		}
		printf("%s\n", inet_ntoa(((struct sockaddr_in *)
		  &ifr.ifr_addr)->sin_addr));
		return "(none)";
	}

	#if 0
	std::string
	ipv6addr(void)
	{
	   struct ifaddrs *ifaddr, *ifa;
           int family, s;
           char host[NI_MAXHOST];

           if (getifaddrs(&ifaddr) == -1) {
               perror("getifaddrs");
               exit(EXIT_FAILURE);
           }

           /* Walk through linked list, maintaining head pointer so we
              can free list later */

           for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
               if (ifa->ifa_addr == NULL)
                   continue;

               family = ifa->ifa_addr->sa_family;

               /* Display interface name and family (including symbolic
                  form of the latter for the common families) */

               printf("%s  address family: %d%s\n",
                       ifa->ifa_name, family,
                       (family == AF_PACKET) ? " (AF_PACKET)" :
                       (family == AF_INET) ?   " (AF_INET)" :
                       (family == AF_INET6) ?  " (AF_INET6)" : "");

               /* For an AF_INET* interface address, display the address */

               if (family == AF_INET || family == AF_INET6) {
                   s = getnameinfo(ifa->ifa_addr,
                           (family == AF_INET) ? sizeof(struct sockaddr_in) :
                                                 sizeof(struct sockaddr_in6),
                           host, NI_MAXHOST, NULL, 0, NI_NUMERICHOST);
                   if (s != 0) {
                       printf("getnameinfo() failed: %s\n", gai_strerror(s));
                       exit(EXIT_FAILURE);
                   }
                   printf("\taddress: <%s>\n", host);
               }
           }

           freeifaddrs(ifaddr);
		return "(none)";
	}
	#endif

	int
	duplex(void)
	{
		initifr();
		memset((void *)&ethcmd, 0, sizeof(struct ethtool_cmd));
		ethcmd.cmd = ETHTOOL_GSET;
		ifr.ifr_data = (caddr_t) &ethcmd;
		int rc = ioctl(sock, SIOCETHTOOL, &ifr);
		if (rc < 0) {
			perror("duplex ioctl");
			return -1;
		}
		switch (ethcmd.duplex) {
			case DUPLEX_FULL: return 1; break;
			case DUPLEX_HALF: return 0; break;
			default: return -1; break;
		}
		return -1;
	}
};

int
main(int argc, char **argv)
{
	//sleep(5);
	ethxinfo *peth = new ethxinfo(argv[1]);
	int linkspeed = -1;
	int linkstatus = peth->linkstatus();
	if (linkstatus) {
		linkspeed = peth->linkspeed();
	}
	printf("%dMbps\n", linkspeed);

	//printf("linkspeed  %d\n", peth->linkspeed());
	//printf("duplex     %d\n", peth->duplex());
	//printf("linkstatus %d\n", peth->linkstatus());
	//printf("mtu	   %d\n", peth->mtu());
	//printf("ipaddr     %s\n", peth->ipv4addr().c_str());
	//printf("ipaddr     %s\n", peth->ipv6addr().c_str());
	//printf("duplex     %d\n", peth->duplex());
}
