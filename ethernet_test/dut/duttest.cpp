#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <string>

#include <errno.h>
#include <linux/sockios.h>
#include "internal.h"

#include "ethif.h"

void
usage(void)
{
}

int
main(int argc, char **argv)
{
    // argv[1] is device name - eth0
    // argv[2] is ip address 
    int linkstatus;

    printf("argc %d\n", argc);
    for (int i=0; i<argc; i++) {
        printf("arg %d, %s\n", argc, argv[i]);
    }

    if (argc < 2) {
        usage();
        exit(1);
    }

    ethif * pethX = new ethif((char *)argv[1]);

    pethX -> getipaddress();
    pethX -> getlinkspeed(NULL);
    pethX -> getphyaddress(NULL);

    pethX->ethdown();

    system("ifconfig eth0 mtu 4096 up");

    pethX->ethdown();

    system("ifconfig eth0 mtu 1500 up");

    pethX -> getpermaddr(NULL);

    sleep(3);

    pethX -> getlinkstatus(&linkstatus);

    pethX -> getlinkstatus(&linkstatus);

    for (int reg=0; reg<32; reg++) {
        pethX -> miiread(reg, NULL); 
    }

    pethX -> getmtu();

    exit(0);
}

