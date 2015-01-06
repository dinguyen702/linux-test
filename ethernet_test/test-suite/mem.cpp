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

int
main(void)
{
	size_t i;
	size_t memsize = (1024*1024*16);

	unsigned char *tbuf = (unsigned char *)malloc(memsize);
	unsigned char *sbuf = (unsigned char *)malloc(memsize);

	if (tbuf == NULL) {
		printf("tbuf NULL!\n");
		exit(1);
	}

	if (sbuf == NULL) {
		printf("sbuf NULL!\n");
		exit(1);
	}

	for (;;) {
		for (i=0; i<memsize; i++) {
			tbuf[i] = rand();
			sbuf[i] = rand();
		}
		memcpy(tbuf, sbuf, memsize);
		memcpy(sbuf, tbuf, memsize);
	}
	

}


