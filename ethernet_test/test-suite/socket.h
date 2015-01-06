
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netinet/ip.h>
#include <errno.h>
#include <signal.h>

class Socket {
	int	sock;

	void
	assertsetsockopt(int err, int line)
	{
		if (err != 0) {
			printf("setsockopt socket.h line %d, err %d, %s\n", line, err, strerror(err));
			exit(1);
		}
		return;
	}
public:
	Socket(int af, int type, int protocol)
	{
		sock = ::socket(af, type, protocol);
		//signal(SIGPIPE, SIG_IGN);
		//int i = 1;
		//setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, &i, sizeof(i));
		printf("Socket %x\n", sock);
		ASSERT(sock);
	}
	
	Socket(int _sock)
	{
		sock = _sock;
		printf("Socket %x\n", sock);
	}

	int
	Connect(IPAddress *paddr)
	{
		int ret;
		ret = ::connect(sock, paddr->getsockaddr(), paddr->getsockaddrlen());
		ASSERT(ret==0);
		return ret;
	}	

	void
	Close()
	{
		close(sock);
	}

	int
	Listen(int backlog)
	{
		int ret;
		ret = ::listen(sock, backlog);
		ASSERT(ret);
		return ret;
	}

	int
	Listen(void)
	{
		int ret;
		ret = ::listen(sock, SOMAXCONN);
		ASSERT(ret==0);
		return ret;
	}

	int
	Bind(IPAddress *paddr)
	{
		int ret;
		ret = ::bind(sock, paddr->getsockaddr(), paddr->getsockaddrlen());
		if (ret <0 ) {
			printf("err %d, %s\n", errno, strerror(errno));
		}
		ASSERT(ret>=0);
		return ret;
	}

	Socket *
	Accept(void)
	{	
		int newsock;
		newsock = ::accept(sock, NULL, NULL);
		ASSERT(newsock > 0);
		printf("ACCEPT! New sock %x\n", newsock);
		Socket *nsock = new Socket(newsock);
		return nsock;
	}

	Socket *
	Accept(IPAddress &addr)
	{	
		sockaddr_storage sa;
		socklen_t sl=sizeof(sa);
		int newsock;
		memset(&sa, 0, sizeof(sa));
		newsock = ::accept(sock, (struct sockaddr *)&sa, &sl);
		ASSERT(newsock > 0);
		IPAddress newaddr(sa);
		addr = newaddr;
		Socket *nsock = new Socket(newsock);
		printf("ACCEPT! New sock %x\n", newsock);
		return nsock;
	}

	int
	Recv(char *recvbuf, int len, int flags)
	{
		//printf("recv sock %d\n", sock);
		int ret = ::recv(sock, recvbuf, len, flags);
		if (ret < 0) {
			printf("recv %d, %s\n", errno, strerror(errno));
		}
		//ASSERT(ret > 0);
		return ret;
	}

	int
	Recv(char *buf, int len, int flags, IPAddress &addr)
	{		
		sockaddr_storage sa;
		socklen_t sl;
		int ret;
		ret = ::recvfrom(sock, buf, len, flags, (struct sockaddr *)&sa, &sl);
		ASSERT(ret >= 0);
		IPAddress newaddr(sa);
		addr = newaddr;
		return ret;
	}

	int
	Send(const char *buf, int len, int flags)
	{
		//printf("Send buf %p, data %s, len %d, flags %d, sock %x\n", 
		//	buf, buf, len, flags, sock);
		int ret = ::send(sock, buf, len, flags | MSG_NOSIGNAL );
		//printf("send returned %d, err %d, %s\n", ret, errno, strerror(errno));
		ASSERT(ret >= 0);
		return ret;
	}	

	int
	Send(const char *buf, int len, int flags, IPAddress *ptoaddr)
	{
		int ret;
		ret = ::sendto(sock, buf, len, flags, ptoaddr->getsockaddr(), ptoaddr->getsockaddrlen());
		ASSERT(ret >= 0);
		return ret;
	}

	int
	DontRoute(void)
	{
		int val = 1;
		int ret;
		ret = setsockopt(sock, SOL_SOCKET, SO_DONTROUTE, &val, sizeof(val));
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	int
	DisableMulticastLoopback()
	{
		int loop=0;
		int ret;
		ret = setsockopt(sock, IPPROTO_IP, IP_MULTICAST_LOOP, &loop, sizeof(loop));
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	int
	EnableMulticastLoopback()
	{
		int loop=1;
		int ret;
		ret = setsockopt(sock, IPPROTO_IP, IP_MULTICAST_LOOP, &loop, sizeof(loop));
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	int
	DisableNagling()
	{
		int flag = 1;
		int ret;
		ret = setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	int
	EnableNagling()
	{
		int flag = 0;
		int ret;
		ret = setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	int
	DisableUdpChecksum()
	{
		int optval = 1;
		int ret;
		ret = setsockopt(sock, SOL_SOCKET, SO_NO_CHECK, &optval, sizeof(optval));
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	int EnableUdpChecksum()
	{
		int optval = 0;
		int ret;
		ret = setsockopt(sock, SOL_SOCKET, SO_NO_CHECK, &optval, sizeof(optval));
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	int AddMulticast(IPAddress *ipaddr)
	{
		int ret;
		ret = setsockopt(sock, IPPROTO_IP, IP_ADD_MEMBERSHIP, (char *)ipaddr->getsockaddr(), ipaddr->getsockaddrlen());
		assertsetsockopt(ret, __LINE__);
		return ret;
	}
	int RemoveMulticast(IPAddress *ipaddr)
	{
		int ret;
		ret = setsockopt(sock, IPPROTO_IP, IP_DROP_MEMBERSHIP, (char *)ipaddr->getsockaddr(), ipaddr->getsockaddrlen());
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	int LocalMulticastIface(IPAddress *ipaddr)
	{	
		int ret;
		ret = setsockopt(sock, IPPROTO_IP, IP_MULTICAST_IF, (char *)ipaddr->getsockaddr(), ipaddr->getsockaddrlen());
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	bool SetNonblocking()
	{
		long on = 1;
		if (ioctl(sock, (int) FIONBIO, (char *) &on)) {
			printf("setting to non blocking failed!\n");
			return false;
		}
		return true;
	}
	int SetBlocking()
	{	
		long on = 0;
		if (ioctl(sock, (int) FIONBIO, (char *) &on)) {
			printf("setting to non blocking failed!\n");
			return false;
		}
		return true;
	}

	std::string GetError(uint32_t *dwerror)
	{
		std::string str;
		int err = errno;
		str = ::strerror(err);
		if (dwerror) {
			*dwerror = err;
		}
		return str;
	}

	int SetMulticastTTL(int ttl)
	{
		int ret;
		ret = setsockopt(sock, IPPROTO_IP, IP_MULTICAST_TTL, (char *)&ttl, sizeof(ttl));
		assertsetsockopt(ret, __LINE__);	
		return ret;
	}

	int DontFragment()
	{
		int df=IP_PMTUDISC_DO;
		int ret;
		ret = setsockopt(sock, IPPROTO_IP, IP_MTU_DISCOVER, (char *)&df, sizeof(df));
		assertsetsockopt(ret, __LINE__);
		return ret;
	}

	int ReuseAddress()
	{
		int on = 1;
		int ret = setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (const char *)&on, sizeof(on));
		assertsetsockopt(ret, __LINE__);
		return ret;
	}
};



