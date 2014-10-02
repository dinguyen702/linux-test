#include <common.h>
#include <exports.h>

#include "arm.h"

//
// TFTP test gets the address from a command line parameter. 
// The size of the file is the first 4 bytes.
//
//

#define LOADADDR 0x100000


long int strtol(char *str, char **nptr, int base);

int uboot_app_main(int argc, char * const argv[])
{
	int i;
	uint8_t ch;
	char *nptr;
	printf("serverip : %s\n", getenv("serverip"));

	if (argc < 2) {
		printf("need load address of tftp file image!\n");
		return 1;
	}
	
	unsigned long loadaddr = hex2dec(argv[1]);
	printf("load addr %x\n", loadaddr);

	//volatile unsigned char *ptr = (unsigned char *)0x40000000;
	unsigned long *pfsize = (unsigned long *) loadaddr;
	unsigned long *pseed = (unsigned long *) (loadaddr+4);
	unsigned char *pdata = (unsigned char *) (loadaddr+8);


	int seed = *pseed;
	int fsize = *pfsize;
	printf("fsize %d\n", fsize);
	printf("seed  %x\n", seed);

	printf("CPU ID %x\n", __get_cpuid());

	printf ("Example expects ABI version %d\n", XF_VERSION);
	printf ("Actual U-Boot ABI version %d\n", (int)get_version());

	printf ("argc = %d\n", argc);

	for (i=0; i<=argc; ++i) {
		printf ("argv[%d] = \"%s\"\n",
			i,
			argv[i] ? argv[i] : "<NULL>");
	}

	unsigned char rnd;
	smyrand(seed);
	for (i=0; i<10; i++) {
		unsigned char expch = myrand();
		if (expch != pdata[i]) {
			printf("fail, offs %d, exp %x, actual %x\n", 
				fsize + 8,
				expch,
				pdata[i]);
			return 0;
		}
		printf("i %d, expch %x, actual %x\n", i, expch, pdata[i]);
	}
//	printf("rand %x\n", (unsigned char) myrand());
	printf("pass!\n");
	return 0;
}

/* No stdlib, so make up our own simple memcpy */
inline void *memcpy(void *dst, const void *src, __kernel_size_t sz)
{
	__kernel_size_t i;
	unsigned char *d = (unsigned char *)dst;
	unsigned char *s = (unsigned char *)src;
	printf("d %x, s %x, sz %d\n", d, s, sz);
	for (i=0; i<sz; i++)
		d[i] = s[i];
	return d;
}
	
void do_undefined_instruction(void)
{
}

void do_software_interrupt(void)
{
}

void do_prefetch_abort(void)
{
}

void do_data_abort(pinterrupt_stack regs)
{	
	register u_long *lnk_ptr;

#if 0
	printf("do_data_abort! dfar %lx, %lx\n", dabort_address, dabort_status );

	printf("r0 %lx\n", regs->r0);
	printf("r1 %lx\n", regs->r1);
	printf("r2 %lx\n", regs->r2);
	printf("r3 %lx\n", regs->r3);
	printf("r4 %lx\n", regs->r4);
	printf("r5 %lx\n", regs->r5);
	printf("r6 %lx\n", regs->r6);
	printf("r7 %lx\n", regs->r7);
	printf("r8 %lx\n", regs->r8);
	printf("r9 %lx\n", regs->r9);
	printf("r10 %lx\n", regs->r10);
	printf("r11 %lx\n", regs->r11);
	printf("r12 %lx\n", regs->r12);
	printf("lr %lx\n", regs->lr);
#endif
#if 0

	__asm__ __volatile__ (
		"sub lr, lr, #8\n"
		"mov %0, lr" : "=r" (lnk_ptr)
	);
	/* On data abort exception the LR points to PC+8 */
	printf("Data Abort at %p 0x%08lX\n", lnk_ptr, *(lnk_ptr));
	for(;;);
#endif
	//printf("data abort! %x\n", regs);
	//show_regs(regs);
	//regs->ARM_sp -= 4;
}

void do_not_use(void)
{
}

void do_irq(void)
{
}

void do_fiq(void)
{
}

