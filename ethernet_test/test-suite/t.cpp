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

#include "ipaddr.h"
#include "socket.h"

void *txfunc(void *arg);
void *rxfunc(void *arg);

int
main(int argc, char **argv)
{
#if 0
	IPAddress *ip = new IPAddress("::3@456");
	printf("ip %p, string %s\n", ip, ip->tostring().c_str());	

	ip = new IPAddress("192.188.2.3@ftp");
	printf("ip %p, string %s\n", ip, ip->tostring().c_str());	

	ip = new IPAddress("192.118.2.3@4578");
	printf("ip %p, string %s\n", ip, ip->tostring().c_str());	

	ip = new IPAddress("34.1.2.3");
	printf("ip %p, string %s\n", ip, ip->tostring().c_str());	

	IPAddress *localif = new IPAddress("192.178.1.124");
	printf("ip %p, string %s\n", localif, localif->tostring().c_str());	

	localif = new IPAddress();
	printf("ip %p, string %s\n", localif, localif->tostring().c_str());	

	localif = new IPAddress(AF_INET);
	printf("ip %p, string %s\n", localif, localif->tostring().c_str());	

	localif = new IPAddress(AF_INET6);
	printf("ip %p, string %s\n", localif, localif->tostring().c_str());	
#endif
	pthread_t txthread, rxthread;
	int txrc, rxrc;

	if (argv[1][0] == 'r') {
		rxrc = pthread_create(&rxthread, NULL, &rxfunc, NULL);
		pthread_join(rxthread, NULL);
	}

	if (argv[1][0] == 't') {
		txrc = pthread_create(&txthread, NULL, &txfunc, NULL);
		pthread_join(txthread, NULL);
	}

	exit(1);
	
	rxrc = pthread_create(&rxthread, NULL, &rxfunc, NULL);
	sleep(1);

	txrc = pthread_create(&txthread, NULL, &txfunc, NULL);

	pthread_join(txthread, NULL);
	pthread_join(rxthread, NULL);

	printf("main sleeping\n");	
	sleep(5);
}

char msg[] = "hello message\n";

char rbf[1025];

void *txfunc(void *arg)
{
	printf("txfunc!\n");
	IPAddress *localif = new IPAddress("localhost");
	printf("ip %p, string %s\n", localif, localif->tostring().c_str());	

	IPAddress *pserver = new IPAddress("localhost@5000");

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

	s->DisableNagling();

	//s->DisableNagling();
	printf("tx send\n");
	s->Send(msg, strlen(msg), 0);
	printf("tx recv\n");
	int bytes = s->Recv(rbf, 1024, 0);
	printf("snd func: recvd %d, %s\n", bytes, rbf);
	printf("tx sleep\n");
	sleep(5);

	return NULL;
}

char rrbuf[1025];

void *rxfunc(void *arg)
{
	printf("rxfunc!\n");

	Socket *s = new Socket(AF_INET, SOCK_STREAM, 0);

	s->ReuseAddress();

	printf("rx bind\n");
	IPAddress *pserver = new IPAddress("localhost@5000");
	s->Bind(pserver);
	printf("rx listen\n");
	s->Listen();

	s->DisableNagling();

	IPAddress client;

	printf("rx accept\n");
	Socket *newSock = s->Accept(client);

	printf("rx recv\n");
	int bytes = newSock->Recv(rrbuf, 1024, 0);
	printf("recv func: recvd %d, %s\n", bytes, rrbuf);
	printf("rx send\n");
	newSock->Send(rrbuf, strlen(rrbuf), 0);

	printf("rx sleep\n");
	sleep(5);
	
	return NULL;
}


void *mainthread(void *arg)
{
	return NULL;
}


