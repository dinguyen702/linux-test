#include <common.h>
#include <exports.h>

#include "arm.h"

volatile int dataabort_handler = 0;

#define BLOCK_SIZE 0x100

unsigned char testblock[BLOCK_SIZE] = { 0 };

int uboot_app_main(int argc, char * const argv[])
{
	int i;
	uint8_t ch;
	uint32_t old_vbar = __get_vbar();
	//printf("serverip : %s\n", getenv("serverip"));
	volatile unsigned char *ptr = (unsigned char *)0x40000000;

	printf("CPU ID %x\n", __get_cpuid());

	return 0;
	printf ("Example expects ABI version %d\n", XF_VERSION);
	printf ("Actual U-Boot ABI version %d\n", (int)get_version());

	printf ("argc = %d\n", argc);

	for (i=0; i<=argc; ++i) {
		printf ("argv[%d] = \"%s\"\n",
			i,
			argv[i] ? argv[i] : "<NULL>");
	}


	printf("__get_vbar() %x, %x\n", old_vbar, &_interrupts);

	__set_vbar( (uint32_t) &_interrupts);

	printf("__get_vbar() %x, %x\n", __get_vbar(), &_interrupts);
	//printf ("cpsr! %x\n", __get_cpsr() );

	//printf ("output! \n" );
	//printf ("stack pointer! %x\n", __get_sp() );
	//printf ("pc! %x\n", __get_pc() );
	//printf ("cpsr! %x\n", __get_cpsr() );

	//for (i=0; i<0x10; i++) {
	//	printf("gmac reg %d, %x => %x\n", i, i*4, readl(SOCFPGA_EMAC1_ADDRESS+i*4));
	//}

	// An aborted write should return 
	// a status of 0x1808
	// An aborted read should return
	// a status of 0x1008

	printf("dataabort_handler %d\n", dataabort_handler);
	for (i=0; i<BLOCK_SIZE; i++) {
		__set_dfar(0);
		__set_dfstatus(0);

		__get_dfstatus();
		__get_dfar();
		printf("i %d\n", i);

		ptr[i] = 0xca;
		if ( (__get_dfstatus() & 0x1008) != 0x1008) {
			printf("write status not expected! %d, %x, %x\n", i, __get_dfstatus(), __get_dfar() );
			return 0;
		}

		__set_dfar(0);
		__set_dfstatus(0);

		//printf("rd cleared status %x, addr %x\n", __get_dfstatus(), __get_dfar());
		__get_dfstatus();
		__get_dfar();


		ch = ptr[i];
		if ( (__get_dfstatus() & 0x1008) != 0x1008) {
			printf("read  status not expected! %d, %x, %x\n", i, __get_dfstatus(), __get_dfar() );
			return 0;
		}
	}

	printf("dataabort_handler %d\n", dataabort_handler);
	__set_dfar(0);
	__set_dfstatus(0);

	ptr = testblock;
	for (i=0; i<BLOCK_SIZE; i++) {
		ptr[i] = 0xff;
		if (__get_dfstatus() != 0) {
			printf("bad dfstatus\n");
		}
		if (__get_dfar() != 0) {
			printf("bad dfar\n");
		}
	}

	printf("dataabort_handler %d\n", dataabort_handler);

	printf ("Example expects ABI version %d\n", XF_VERSION);
	printf ("Actual U-Boot ABI version %d\n", (int)get_version());

	printf ("argc = %d\n", argc);

	for (i=0; i<=argc; ++i) {
		printf ("argv[%d] = \"%s\"\n",
			i,
			argv[i] ? argv[i] : "<NULL>");
	}
	printf("concluding test!\n");	
	printf("concluding test!\n");	

	/* Print the ABI version */
	//app_startup(argv);
	/* Restore old VBAR that we read at program entry */

	__set_vbar(old_vbar);
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

//void do_data_abort(void) __attribute__((naked));
void do_data_abort(pinterrupt_stack regs)
{	
	register u_long *lnk_ptr;

	dataabort_handler++;
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

