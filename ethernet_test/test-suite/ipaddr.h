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

class IPAddress {
private:
public:
	struct sockaddr_storage m_sas;	// sockaddr_storage, cast to 
									// sockaddr_in and sockaddr_in6
									// as needed.
	void
	construct(const sockaddr &addr)
	{
		ASSERT((addr.sa_family == AF_INET) || (addr.sa_family==AF_INET6));
		if (addr.sa_family == AF_INET6) {
			memcpy(&m_sas, &addr, sizeof(struct sockaddr_in6));
		} else if (addr.sa_family == AF_INET) {
			memcpy(&m_sas, &addr, sizeof(struct sockaddr_in));
		} else { 
			printf("family not supported!\n");
			exit(1);	
		}
	}

	int
	getfamily(void) const
	{
		return m_sas.ss_family;
	}

	void
	_IPAddress(const char *pip, const char *pport, int afhint)
	{
	    struct addrinfo hints, *res;
    	int status;

    	memset(&hints, 0, sizeof(hints));
		memset(&m_sas, 0, sizeof(sockaddr_storage));

    	hints.ai_family = afhint;
    	hints.ai_socktype = 0;
    	/* Setting AI_PASSIVE will give you a wildcard address if addr is NULL */
    	//hints.ai_flags = AI_NUMERICHOST | AI_NUMERICSERV | AI_PASSIVE;
    	hints.ai_flags = AI_PASSIVE;

    	if ((status = getaddrinfo(pip, pport, &hints, &res)) != 0) {
        	fprintf(stderr, "getaddrinfo: (%s) (%s) %s\n", 
				pip, pport,
				gai_strerror(status));
        	return;
    	}
		struct sockaddr *sa = res->ai_addr;
		printf("family %d, %d\n", res->ai_family, sa->sa_family);
    	/* Note, we're taking the first valid address, there may be more than one */
    	memcpy(&m_sas, res->ai_addr, res->ai_addrlen);
		setport( atoi(pport) );
		printf("laddr family : %d, addr %s\n", m_sas.ss_family, tostring().c_str());
    	freeaddrinfo(res);	
	}

	const struct sockaddr *getsinaddr(void) const
	{
		struct sockaddr_in6 *in6 = (struct sockaddr_in6 *) &m_sas;
		struct sockaddr_in *in4 = (struct sockaddr_in *)  &m_sas;
		int fam = m_sas.ss_family;
		switch (fam) {
		case AF_INET:
			return (const struct sockaddr *)&(in4->sin_addr);
			break;
		case AF_INET6:
			return (const struct sockaddr *)&(in6->sin6_addr);
			break;
		default:
			printf("invalid family in get sockaddr %d\n", fam);
			return NULL;
			break;
		}
	}

public:

	IPAddress(void)
	{
		_IPAddress(NULL, "0", AF_UNSPEC);
	}

	IPAddress(int af)
	{
		_IPAddress(NULL, "0", af);
	}

	IPAddress(std::string ipaddrstr)
	{
		std::vector<std::string> elems = split(ipaddrstr, '@');
		std::string ipaddr, port;

		// check vector size, make sure it's 2.
		// check characters in ipaddress, make sure they're what are
		// expected.
		// check port characters, make sure they are expected
		if (elems.size() == 2) {
			ipaddr = elems[0];
			port = elems[1];
		} else if (elems.size()==1) {
			ipaddr = elems[0];
			port   = "0";
		} else {
			throw "ipaddress not formatted as expected";
		}

		_IPAddress(ipaddr.c_str(), port.c_str(), AF_UNSPEC);
	}

	IPAddress(std::string ipaddrstr, int af)
	{
		std::vector<std::string> elems = split(ipaddrstr, '@');
		std::string ipaddr, port;

		// check vector size, make sure it's 2.
		// check characters in ipaddress, make sure they're what are
		// expected.
		// check port characters, make sure they are expected
		if (elems.size() == 2) {
			ipaddr = elems[0];
			port = elems[1];
		} else if (elems.size()==1) {
			ipaddr = elems[0];
			port   = "0";
		} else {
			throw "ipaddress not formatted as expected";
		}

		_IPAddress(ipaddr.c_str(), port.c_str(), af);
	}

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
		return (const struct sockaddr *)&m_sas;
	}

	socklen_t getsockaddrlen(void) const
	{
		if (m_sas.ss_family == AF_INET)
			return sizeof(struct sockaddr_in);
		else if (m_sas.ss_family == AF_INET6)
			return sizeof(struct sockaddr_in6);

		printf("incorrect family in getsockaddrlen %d\n", m_sas.ss_family);
		ASSERTMSG(0, "Incorrect family setting detected in getsockaddrlen()\n");
		return 0;
	}

	uint16_t getport(void) const
	{
		struct sockaddr_in6 *in6 = (struct sockaddr_in6 *) &m_sas;
		struct sockaddr_in *in4 = (struct sockaddr_in *)  &m_sas;
		if (m_sas.ss_family == AF_INET)
			return htons(in4->sin_port);
		else if (m_sas.ss_family == AF_INET6)
			return htons(in6->sin6_port);
		printf("unexpected family in getport %d\n", m_sas.ss_family);
		ASSERTMSG(0, "Incorrect family setting detected in getport()\n");
		return -1;
	}

	void setport(uint16_t portn) 
	{
		struct sockaddr_in6 *in6 = (struct sockaddr_in6 *) &m_sas;
		struct sockaddr_in *in4 = (struct sockaddr_in *)  &m_sas;
		if (m_sas.ss_family == AF_INET) {
			in4->sin_port = htons(portn);
			return; 
		} else if (m_sas.ss_family == AF_INET6) {
			in6->sin6_port = htons(portn);
			return;
		}
		printf("unexpected family in getport %d\n", m_sas.ss_family);
		ASSERTMSG(0, "Incorrect family setting detected in getport()\n");
		return;
	}

	std::string tostring(void) const
	{
		char s[128];
		char sp[64];
		memset(s, 0, 128);
		memset(s, 0, 64);
		int fam = getfamily();
		sprintf(sp, "@%d", getport());
		::inet_ntop(fam, getsinaddr(), (char *)s, 127); 
		strcat(s, sp);
		std::string str(s, strlen(s));
		return str;
	}
};

