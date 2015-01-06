#include <stdio.h>
#include <string>
#include <sstream>
#include <iterator>
#include <iostream>
#include <algorithm>
#include <string.h>
#include <sys/types.h>
#include <stdlib.h>
#include <vector>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include "ipaddr.h"
#include "socket.h"
#include "dbgassert.h"

class socketWorker;

void *
socketWorkerThread(void *psocket);

// poll the socket(s) for receives, nonblocking mode?

// allow multiple ip addresses per socket worker item?

// set SO_REUSE option

// disable local loopback for multicast

// to "bind" to a particular interface from the client side
// struct sockaddr_in localAddr;
// localAddr.sin_family = AF_INET | AF_UNSPEC | AF_INET6;
// localAddr.sin_addr.s_addr = inet_addr(localip)
//
// bind(socket, (struct sockaddr *)&localAddr, sizeof(localAddr));
//
// Other way on Linux is to use SO_BINDTODEVICE

// test for multicast
// 	ipv4_is_multicast()
// 	ipv6_addr_is_multicast()

// string to ip address - inet_pton
// ip address to string - inet_ntop

//
// -S 10 -s -tu,T,x=1,a=2,l=192.178.1.2,m=3456,p=4567,n  
// -s -t l=127.0.0.1 -u -b=25000 -m=224.0.0.1@34 -m=224.0.0.1@35 -a=0 -x=2 -T -e -R -u -n
class socketWorker {
private:
	unsigned long long 
	getusecs(void)
	{
		struct timespec ts;
		unsigned long long tm;
		clock_gettime(CLOCK_MONOTONIC, &ts);
		tm = ts.tv_sec;
		tm = tm * 1000000ULL;
		tm += ts.tv_nsec/1000;
		return tm;
	}

	unsigned long long
	timedelta(unsigned long long start)
	{
		return getusecs()-start;
	}

	unsigned long	
	mbps(unsigned long long bytes, unsigned long long usecs)
	{
		double bits = bytes * 8;
		double dmbps = bits/usecs;
		return (unsigned long)dmbps;
	}

	void *
	sender(void)
	{
		// transmit for 10 seconds. 
		unsigned long long usecs = seconds*1000000ULL;
		unsigned long long starttime;

		printf("worker - sender!\n");
		printf("txfunc!\n");

		sendBuffer = new char [messageSize];
		if (vLocalIP.size() != 1) {
			printf("need one and only one local IP address\n");
			exit(1);
		}

		IPAddress *localif = vLocalIP.at(0);
		printf("ip %p, string %s\n", localif, localif->tostring().c_str());	

		if (vDestIP.size() != 1) {
			printf("need one and only one local IP address\n");
			exit(1);
		}

		IPAddress *pserver = vDestIP.at(0);
		Socket *s = new Socket(AF_INET, SOCK_STREAM, 0);
	

		s->ReuseAddress();

		printf("tx bind\n");
		s->Bind(localif);

		//s->DisableMulticastLoopback();
		//s->EnableMulticastLoopback();
		//s->LocalMulticastIface(localif);
		//s->DisableNagling();
		//s->EnableNagling();
		//s->DisableUdpChecksum();
		//s->EnableUdpChecksum();
		//s->AddMulticast(pserver);
		//s->RemoveMulticast(pserver);
		//s->SetNonblocking();
		//s->SetBlocking();
		//s->GetError(NULL);
		//s->SetMulticastTTL(64);
		//s->DontFragment();	

		//printf("tx bind\n");
		//s->Bind(localif);
		//printf("tx dont route\n");
		//s->DontRoute();
		printf("tx connect\n");
		s->Connect(pserver);

		if (bNoTcpDelay) {
			s->DisableNagling();
		}

		//s->DisableNagling();
		printf("tx send\n");
		
		starttime = getusecs();
		unsigned long long total=0;
		do {
			s->Send(sendBuffer, messageSize, 0);
			total += messageSize;
		} while ( ( getusecs() - starttime ) < usecs ) ;

		printf("total %lld, mbps %d\n", total, mbps(total, usecs) );

		//printf("tx recv\n");
		//int bytes = s->Recv(rbf, 1024, 0);
		//printf("snd func: recvd %d, %s\n", bytes, rbf);

		printf("tx exit\n");

		return NULL;
	}

	void *
	receiver(void)
	{
		unsigned long long usecs = seconds*1000000ULL;
		unsigned long long starttime;

		printf("worker - receiver!\n");
		printf("rxfunc!\n");
		recvBuffer = new char [messageSize];
		Socket *s = new Socket(AF_INET, SOCK_STREAM, 0);

		s->ReuseAddress();

		// get IP address from vLocalIP -- required. 
		if (vLocalIP.size() != 1) {
			printf("need one and only one local IP address\n");
			exit(1);
		}
		printf("rx bind\n");
		IPAddress *pserver = vLocalIP.at(0);//[0]
		s->Bind(pserver);
		printf("rx listen\n");
		s->Listen();

		if (bNoTcpDelay) {
			s->DisableNagling();
		}

		IPAddress client;

		printf("rx accept\n");
		Socket *newSock = s->Accept(client);

		printf("rx recv\n");

		starttime = getusecs();
		int bytes;
		unsigned long long total=0;
		bool cond = true;
		do {
			bytes = newSock->Recv(recvBuffer, messageSize, 0);
			total += bytes;
			cond = usecs ? (getusecs()-starttime)<usecs : true;
		} while  ( cond && (bytes > 0) )  ;

		s->Close();
	
		printf("total %lld, mbps %d\n", total, mbps(total, timedelta(starttime)) );
	
		//printf("recv func: recvd %d, %s\n", bytes, rrbuf);
		//printf("rx send\n");
		//newSock->Send(rrbuf, strlen(rrbuf), 0);

		printf("rx exit\n");
	
		return NULL;
	}

public:
	char		*sendBuffer;
	char		*recvBuffer;
	// tx == 0, rx == 1
	int		txrxType;
	bool		bStats;
	bool		bUdp; // TCP is default
	bool		bTouch;
	bool		bEcho;
	bool		bNoUdpChecksum;
	bool		bNoTcpDelay;
	bool		bForceIPv6;
	int		priority;
	int		affinity;
	int		sockbufsize;
	int		seconds;
	int 		messageSize; // equates to the recv/send size 

	// IP addresses to listen from
	std::vector<class IPAddress *> vSrcIPs;

	// IP Addresses to send to 
	std::vector<class IPAddress *> vDestIP;

	// Local interface to bind to, could be empty 
	std::vector<class IPAddress *> vLocalIP;

	socketWorker(int type)
	{
		txrxType = type;
		bStats = false;
		bTouch = false;
		bEcho = false;
		bNoUdpChecksum = false;
		bNoTcpDelay = false;
		bForceIPv6 = false;
	}

	// this method kicks off a worker thread for this
	// context
	pthread_t	
	startWorker(void)
	{
		int iret;
		pthread_t tid;
		iret = pthread_create(&tid, NULL, 
			&socketWorkerThread, 
			(void*)this);

		ASSERT(iret == 0);

		return tid;
	}

	void *
	worker(void)
	{
		void *pstatus = NULL;
		printf("worker!\n");	

		printf("txrx	%d\n", txrxType);
		printf("bStats  %d\n", bStats);
		printf("bTouch  %d\n", bTouch);
		printf("bEcho   %d\n", bEcho);
		printf("bUdp    %d\n", bNoUdpChecksum);
		printf("bNagle  %d\n", bNoTcpDelay);
		printf("bIPv6	%d\n", bForceIPv6);
		//if (psock->vLocalIP.size() == 1) {
		//	printf("localAddr %s\n", psock->vLocalIP[0]->tostring().c_str());
		//	
		//}
		for (std::vector<IPAddress *>::iterator ipit = vLocalIP.begin();
			ipit != vLocalIP.end(); ipit++) {

			IPAddress *ip = *ipit;
			printf("ipaddr %s\n", ip->tostring().c_str() );
		}

		switch (txrxType) {
		case 0:
			pstatus = sender();
			break;
		case 1:
			pstatus = receiver();
			break;
		default:
			break;
		}
		return pstatus;
	}
};

std::vector<socketWorker *> vSockets;
std::vector<pthread_t> vThreads;

//char ipv6[] = "::3@564";
//char ipv4[] = "192.167.1.1@562";

//char ipv62[] = "::6";
//char ipv42[] = "199.188.4.5";

int main(int argc, char *argv[])
{
	//IPAddress *ip1 = new IPAddress(ipv6);
	//IPAddress *ip2 = new IPAddress(ipv4);
	//IPAddress *ip3 = new IPAddress(ipv62);
	//IPAddress *ip4 = new IPAddress(ipv42);
	//printf("ip1 %s\n", ip1->tostring().c_str());
	//printf("ip2 %s\n", ip2->tostring().c_str());
	//printf("ip3 %s\n", ip3->tostring().c_str());
	//printf("ip4 %s\n", ip4->tostring().c_str());
	//printf("main!\n");
	//if (cmdOptionExists(argv, argv+argc, "-h")) {
	//	printf("help\n");
	//}

	//char *filename = getCmdOption(argv, argv+argc, "-f");
	//if (filename) {
	//	/'printf("filename %s\n", filename);
	//}

	socketWorker *psocket = NULL;
    	std::string stroption;
	int seconds=0;
	int priority=0;
	int affinity = -1;
	int sockbufsize = 8192; // default socket buffer size?
    	IPAddress *pipaddr=NULL;
	for (int i=1; i<argc; i++) {
		int strOptLen = strlen(argv[i]);
		printf("%s strOptLen %d\n", argv[i], strOptLen);
		switch (argv[i][1]) {
		// global option: open a new transmit thread context
		case 't':
			printf("t\n");
			psocket = new socketWorker(0);
			psocket->seconds = seconds;
			psocket->sockbufsize = sockbufsize;
			vSockets.push_back(psocket);
			break;
//		// Device to use - eth0 for example. 
//		// use SO_BINDTODEVICE
//		case 'D':
//			printf("D\n");
//			break;
		// global option: open a new receive thread context
		case 'r':
			printf("r\n");
			psocket = new socketWorker(1);
			psocket->seconds = seconds;
			psocket->sockbufsize = sockbufsize;
			vSockets.push_back(psocket);
			break;

		case 'm':
			stroption.assign( &argv[i][2], strlen(&argv[i][2]) );
			if (psocket) {
				psocket->messageSize = atoi(stroption.c_str());
			}
			break;	
		// thread specific: maintain stats
		case 's':
			printf("s\n");
			if (psocket) {
				psocket->bStats = true;
			}
			break;

		case '6':
			printf("6\n");
			if (psocket) {
				psocket->bForceIPv6 = true;
			}
			break;
		// thread specific: interface to use
		case 'l':
			stroption.assign( &argv[i][2], strlen(&argv[i][2]) );
			printf("l %s\n", stroption.c_str());
			if (psocket) {
				pipaddr = new IPAddress(stroption);
				printf("pushing pipaddr %p, string %s\n", pipaddr, pipaddr->tostring().c_str() );
				psocket->vLocalIP.push_back(pipaddr);
			}
			break;

		// thread specific - socket buffer size to use
		case 'b':
			stroption.assign( &argv[i][2], strlen(&argv[i][2]) );
			printf("b\n");
			sockbufsize = atoi(stroption.c_str());
			break;

		// multicast address to use - used for the
		// receiver thread, can have as many as you want.
		// receive uses SIOCADDMULTI to add multicast
		// to listener list
		// strike above for now, just get a destination IP
		// address and get that working for now
		case 'i':
			stroption.assign( &argv[i][2], strlen(&argv[i][2]) );
			printf("i\n");
			if (psocket) {
				pipaddr = new IPAddress(stroption);
				psocket->vDestIP.push_back(pipaddr);
			}
			break;
		// affinity
		case 'a':
			stroption.assign( &argv[i][2], strlen(&argv[i][2]) );
			printf("a\n");
			if (psocket) {
				psocket->affinity = atoi(stroption.c_str());
			}
			break;
		// priority		
		case 'x':
			stroption.assign( &argv[i][2], strlen(&argv[i][2]) );
			printf("x\n");
			if (psocket) {
				psocket->priority = atoi(stroption.c_str());
			}
			break;
		// touch the data - touch all data bytes before sending and/or
		// receiving, otherwise just send or receive
		case 'T':
			printf("T\n");
			if (psocket) {
				psocket->bTouch = true;
			}
			break;
		// "echo" the data back to the sender - server only
		case 'e':
			printf("e\n");
			if (psocket) {
				psocket->bEcho = true;
			}
			break;
		// "relay" the data, server option only - specify the
		// ip and port to relay data to
		case 'R':
			printf("R\n");
			break;
		// no udp checksum option
		case 'u':
			printf("u\n");
			if (psocket) {
				psocket->bNoUdpChecksum = true;
			}
			break;
		// no delay
		case 'n':
			printf("n\n");
			if (psocket) {
				psocket->bNoTcpDelay = true;
			}
			break;
		// Seconds
		case 'S':
			printf("S\n");
			stroption.assign( &argv[i][2], strlen(&argv[i][2]) );
			seconds = atoi(stroption.c_str());

			// the C++ way, using a c++11 compiler that I
			// apparently do not have.
			//seconds = std::stoi(stroption);
			printf("%d seconds %s seconds\n", seconds, stroption.c_str());
			break;
		default: 
			printf("unsupported option %c\n", argv[i][1]);
			exit(1);
			break;
		}
	}

	
	for (std::vector<socketWorker *>::iterator it = vSockets.begin(); 
		it!=vSockets.end(); it++) {

		//socketWorker *psock = *it;
		//if (psock->vLocalIP.size() == 1) {
		//	printf("localAddr %s\n", psock->vLocalIP[0]->tostring().c_str());
		//	
		//}
		for (std::vector<IPAddress *>::iterator ipit = (*it)->vLocalIP.begin();
				ipit != (*it)->vLocalIP.end(); ipit++) {
			IPAddress *ip = *ipit;
			printf("ipaddr %s\n", ip->tostring().c_str() );
		}
		pthread_t tid = (*it)->startWorker();	
		vThreads.push_back(tid);
	}

	//printf("%d \n", getaddrfamily(ipv4));
	//printf("%d \n", getaddrfamily(ipv6));

	// roll through the socketItems picked up and configured
	// by parsing and processing the command line options.

	// as each item is validated, startup the thread

	
	for (std::vector<pthread_t>::iterator it = vThreads.begin(); it!=vThreads.end(); it++) {
		pthread_join(*it, NULL);
	}

	return 0;
}

char *getCmdOption(char **begin, char **end, const std::string &option)
{
	char **itr = std::find(begin, end, option);
	if (itr != end && ++itr != end) {
		return *itr;
	}
	return 0;
}

bool cmdOptionExists(char **begin, char **end, const std::string &option)
{
	return std::find(begin, end, option) != end;
}

void *
socketWorkerThread(void *psocket)
{
	socketWorker *psock = (socketWorker *) psocket;
	printf("SocketWorker!\n");
	
	do {
		psock->worker();
	} while (psock->seconds == 0) ;	

	return NULL; 
}


