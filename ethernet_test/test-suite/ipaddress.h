
#include <string>
#include <sstream>
#include <iostream>
#include <vector>
#include "dbgassert.h"

inline std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems)
{
	std::stringstream ss(s);
	std::string item;
	while (std::getline(ss, item, delim)) {
		elems.push_back(item);
	}
	return elems;
}

inline std::vector<std::string> split(const std::string &s, char delim)
{
	std::vector<std::string> elems;
	split(s, delim, elems);
	return elems;
}

inline bool
chkstring(std::string ipaddr, char *carray)
{
	char *chk = carray;
	bool ok = true;
	const char *sip = ipaddr.c_str();
	
	// iterate through ipaddr, checking each character to see if
	// exists in the chkchars string, if not, then
	// this string is invalid.
  	while (*sip != '\0') {
		char ch = *sip;
		bool found = false;
		for (int i=0; i<strlen(chk); i++) {
			if (ch == chk[i]) {	
				found = true;
				continue;
			}
		}
		if (!found) {
			return false;
		}
		sip++;
	}		
		
	return ok;
}
	
inline bool
checknumberstr(std::string strport)
{
	char chk[] = "0123456789";
	return chkstring(strport, chk);
}


class IPAddress {
private:
public:
	int				afhint; 		// what the user provides to 
								  	// bias getaddrinfo result

	int				aifamily; 		// AF_INET, or AF_INET6
	int				portnum;

	struct sockaddr_storage laddr;

	char 			abuffer[128];

	std::string		ipaddr;
	std::string		port;
	std::string 	ipaddrportstr;	// The string as provided by the user

	int
	getaddrfamily(const char *addr)
	{
		struct addrinfo hint, *info= NULL;
		memset(&hint, 0, sizeof(hint));
		hint.ai_family = AF_UNSPEC; // use AF_INET6 to force IPv6

		int ret = getaddrinfo(addr, 0, &hint, &info);
		if (ret) 
			return -1;

        int result = info->ai_family;
		freeaddrinfo(info);
		return result;
	}

	bool
	checkipaddrstr(std::string strip)
	{
		char chk[] = "0123456789.:@";
		return chkstring(strip, chk);
	}
	
	void
	construct(const sockaddr &addr)
	{
		ASSERT((addr.sa_family == AF_INET) || (addr.sa_family==AF_INET6));
		if (addr.sa_family == AF_INET6) {
			memcpy(&laddr, &addr, sizeof(struct sockaddr_in6));
		} else if (addr.sa_family == AF_INET) {
			memcpy(&laddr, &addr, sizeof(struct sockaddr_in));
		} else { 
			printf("family not supported!\n");
			exit(1);	
		}
	}

	int
	getfamily(void) const
	{
		//struct sockaddr_in6 *in6 = (struct sockaddr_in6 *) &laddr;
		//struct sockaddr_in *in4 = (struct sockaddr_in *)  &laddr;
		//printf("in4 family %d, in6 family %d, ss family %d\n", in4->sin_family, in6->sin6_family,
	    //    laddr.ss_family);
		return laddr.ss_family;
	}
public:

	IPAddress(std::string str)
	{
		ipaddrportstr = str;
	    struct addrinfo hints, *res;
    	int status;
    	char port_buffer[6];
		//port = 34;
    	//sprintf(port_buffer, "%hu", port);

    	memset(&hints, 0, sizeof(hints));
    	hints.ai_family = AF_UNSPEC;
    	hints.ai_socktype = SOCK_STREAM;
    	/* Setting AI_PASSIVE will give you a wildcard address if addr is NULL */
    	hints.ai_flags = AI_NUMERICHOST | AI_NUMERICSERV | AI_PASSIVE;

    	if ((status = getaddrinfo(str.c_str(), NULL, &hints, &res)) != 0) {
        	fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(status));
        	return;
    	}
		struct sockaddr *sa = res->ai_addr;
		printf("family %d, %d\n", res->ai_family, sa->sa_family);
    	/* Note, we're taking the first valid address, there may be more than one */
    	memcpy(&laddr, res->ai_addr, res->ai_addrlen);
		printf("laddr family : %d, addr %s\n", laddr.ss_family, tostring().c_str());
    	freeaddrinfo(res);	
	}

#if 0
	IPAddress(std::string str, int afh)
	{
		ipaddrportstr = str;
		afhint = afh;
		std::vector<std::string> elems = split(str, '@');

		// check vector size, make sure it's 2.
		// check characters in ipaddress, make sure they're what are
		// expected.
		// check port characters, make sure they are expected
		if ( (elems.size() == 2) &&
		     (checkipaddrstr(elems[0])) &&
	             (checknumberstr(elems[1])) 
		   ) {
			ipaddr = elems[0];
			port = elems[1];
		} else if ((elems.size()==1) && (checkipaddrstr(elems[0]))) {
			ipaddr = elems[0];
			port   = "";
		} else {
			throw "ipaddress not formatted as expected";
		}
		printf("vect size %d\n", elems.size());
		printf("elem 0 %s\n", elems[0].c_str());
		
		aifamily = getaddrfamily(ipaddr.c_str());
		printf("aifamily %d, %s\n", aifamily, ipaddr.c_str());
		//struct addrinfo hint, *info= NULL;
		//memset(&hint, 0, sizeof(hint));
		//hint.ai_family = AF_UNSPEC; // use AF_INET6 to force IPv6

		//int ret = getaddrinfo(addr, 0, &hint, &info);
		//if (ret) 
		//	return -1;

        //int result = info->ai_family;
		//freeaddrinfo(info);
		int ret;
		//sau.sa.sa_family = aifamily;
		if (aifamily == AF_INET) {
			ret = inet_pton(aifamily, ipaddr.c_str(), &(sa4.sin_addr));
		} else if (aifamily == AF_INET6) {
			ret = inet_pton(aifamily, ipaddr.c_str(), &(sa6.sin6_addr));
		} else {	
			printf("invalid aifamily %d\n", aifamily);
			throw "invalid aifamily";
		}
		if (ret != 1) {
			printf("inet_pton returned %d\n", ret);
			throw "inet_pton returned invalid results";
		}
	    //sau.sa.sa_family = aifamily;	
		
		printf("ipaddr to string %d, %s\n", aifamily, tostring().c_str());
		//printf("elem 0 %s\n", elems[0].c_str());
		//printf("elem 1 %s\n", elems[1].c_str());
		//printf("vect size %d\n", elems.size());
		//ipaddr = elems[0];
		//port   = elems[1];
		printf("check %d\n", checkipaddrstr(ipaddr));
		printf("check %d\n", checknumberstr(port));
		aifamily = getaddrfamily(ipaddr.c_str());
	}
#endif
	IPAddress(const sockaddr &addr)
	{
		construct(addr);
	}

	IPAddress(const sockaddr_storage &addr)
	{
		construct(*(sockaddr*)&addr);
	}
	
	const struct sockaddr *getsockaddr(void) const
	{
		struct sockaddr_in6 *in6 = (struct sockaddr_in6 *) &laddr;
		struct sockaddr_in *in4 = (struct sockaddr_in *)  &laddr;
		int fam = laddr.ss_family;
		switch (fam) {
		case AF_INET:
			return (const struct sockaddr *)&(in4->sin_addr);
			break;
		case AF_INET6:
			return (const struct sockaddr *)&(in6->sin6_addr);
			break;
		default:
			printf("invalid family in get sockaddr %d\n", aifamily);
			return NULL;
			break;
		}
		//return (struct sockaddr *)&sau.sa;
	}

	socklen_t getsockaddrlen(void) const
	{
		if (aifamily == AF_INET)
			return sizeof(struct sockaddr_in);
		else if (aifamily == AF_INET6)
			return sizeof(struct sockaddr_in6);

		printf("incorrect family in getsockaddrlen %d\n", aifamily);
		ASSERTMSG(0, "Incorrect family setting detected in getsockaddrlen()\n");
		return 0;
	}

	uint16_t getport(void) const
	{
		struct sockaddr_in6 *in6 = (struct sockaddr_in6 *) &laddr;
		struct sockaddr_in *in4 = (struct sockaddr_in *)  &laddr;
		if (aifamily == AF_INET)
			return htons(in4->sin_port);
		else if (aifamily == AF_INET6)
			return htons(in6->sin6_port);
		printf("unexpected family in getport %d\n", aifamily);
		ASSERTMSG(0, "Incorrect family setting detected in getport()\n");
		return -1;
	}

	std::string tostring(void) const
	{
		int fam = getfamily();
		printf("this %p, family %d in tostring\n", this, fam);
		::inet_ntop(fam, getsockaddr(), (char *)abuffer, 127); 
		printf("inet_ntop ret string %s\n", abuffer);
		std::string str(abuffer, strlen(abuffer));
		return str;
	}
};

class test {
public:
	std::string mstr;
	test(std::string str)
	{
		mstr = str;
	}

};
