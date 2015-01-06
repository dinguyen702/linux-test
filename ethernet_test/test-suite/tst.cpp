#include <stdio.h>
#include <algorithm>
#include <string.h>
#include <sys/types.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>

#include "ipaddress.h"

int
main(void)
{
	struct sockaddr_in6 sa;
	char str[INET6_ADDRSTRLEN];

	inet_pton(AF_INET6, "::3", &(sa.sin6_addr));	
	inet_ntop(AF_INET6, &sa.sin6_addr, str, INET6_ADDRSTRLEN);

	printf("%s\n", str);

	IPAddress *ip = new IPAddress("::3");

	printf("ipaddr %s\n", ip->ipaddrportstr.c_str());

	printf("ip %p, string %s\n", ip, ip->tostring().c_str());	

	//test *pt = new test("hello");
	//printf("test str %s\n", pt->mstr.c_str());	
}


