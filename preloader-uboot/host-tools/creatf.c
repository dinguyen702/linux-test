#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "myrand.h"

void help(char *str)
{
	printf("Usage: %s seed size filename\n", str);
}

int main(int argc, char **argv)
{
	struct stat filestat;
	if (argc < 4) {
		help(argv[0]);
		exit(1);
	}

	int lseed = atoi(argv[1]);
	smyrand(lseed);
	int fsize = atoi(argv[2]);
	unsigned char rnd;	
	FILE *ofile = NULL;
	int i;

	ofile = fopen(argv[3], "wb");
	if (ofile == NULL) {
		printf("cannot open file for writing!\n");
		exit(1);
	}

	// first write the filesize
	if ( fwrite(&fsize, 1, 4, ofile) != 4) {
		printf("cannot write size\n");
		exit(1);
	}

	// then the seed value
	if ( fwrite(&lseed, 1, 4, ofile) != 4) {
		printf("cannot write seed value\n");
		exit(1);
	}

	for (i=0; i<fsize; i++) {
		rnd = (unsigned char) myrand(); 
		if ( fwrite(&rnd, 1, 1, ofile) != 1) {
			printf("cannot write file!\n");
			fclose(ofile);
			exit(1);
		}
	}

	fclose(ofile);

	int fileno = open(argv[3], O_RDONLY);
	if (fileno < -1) {
		printf("cannot open and stat file!\n");
		exit(1);
	}
	if (fstat(fileno, &filestat) < 0) {
		printf("cannot open and stat file!\n");
		exit(1);
	}

	printf("Wrote %ld bytes to file %s using seed %d, fsize %d\n",
		filestat.st_size, 
		argv[3], lseed, fsize);
}
