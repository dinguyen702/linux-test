
#include "myrand.h"

/* A very simple linear congruential generator. 
 * this was written so that we're sure random sequences 
 * generated on the host side (x86, 32 or 64 bit) and
 * running on ARM processors are deterministic given 
 * the same seed value. These things can be implemented
 * differently by different C run time libraries, this
 * makes sure the library behaves the same. 
 */
static int rseed = 0;
 
void smyrand(int x)
{
	rseed = x;
}
 
int myrand()
{
	return rseed = (rseed * 1103515245 + 12345) & MYRAND_MAX;
}
