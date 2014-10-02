#include <common.h>
#include <exports.h>

#include "arm.h"

/*
 * r8 holds the pointer to the global_data, ip is a call-clobbered
 * register
 */
#define EXPORT_FUNC(x) \
	asm volatile (			\
"	.globl " #x "\n"		\
#x ":\n"				\
"	ldr	ip, [r8, %0]\n"		\
"	ldr	pc, [ip, %1]\n"		\
	: : "i"(offsetof(gd_t, jt)), "i"(XF_ ## x * sizeof(void *)) : "ip");

/* This function is necessary to prevent the compiler from
 * generating prologue/epilogue, preparing stack frame etc.
 * The stub functions are special, they do not use the stack
 * frame passed to them, but pass it intact to the actual
 * implementation. On the other hand, asm() statements with
 * arguments can be used only inside the functions (gcc limitation)
 */
void __attribute__((unused)) dummy(void)
{
	#include <_exports.h>
}

extern unsigned long __bss_start, _end;

int crt_startup(int argc, char * const *argv)
{
	unsigned char * cp = (unsigned char *) &__bss_start;

	unsigned long cpuid = __get_cpuid();

	/* Zero out BSS */
	while (cp < (unsigned char *)&_end) {
		*cp++ = 0;
	}

	return uboot_app_main(argc, argv);
}

#undef EXPORT_FUNC

unsigned int __aeabi_uidiv(unsigned int num, unsigned int den)
{
   unsigned int      x;
   for (x = den; x < num; x += den);
   return x;
}

// first year college implementation, hopefully this is right...
int
hex2dec(char *str)
{
	int i = 0;
	int val = 0;
	int digit = 0;
	while (str[i] != 0) {
		val = val * 16;
		switch (str[i]) {
			case '0':
				digit = 0;
				break;
			case '1':
				digit = 1;
				break;
			case '2':
				digit = 2;
				break;
			case '3':
				digit = 3;
				break;
			case '4':
				digit = 4;
				break;
			case '5':
				digit = 5;
				break;
			case '6':
				digit = 6;
				break;
			case '7':
				digit = 7;
				break;
			case '8':
				digit = 8;
				break;
			case '9':
				digit = 9;
				break;
			case 'a':
			case 'A':
				digit = 10;
				break;
			case 'b':
			case 'B':
				digit = 11;
				break;
			case 'c':
			case 'C':
				digit = 12;
				break;
			case 'd':
			case 'D':
				digit = 13;
				break;
			case 'e':
			case 'E':
				digit = 14;
				break;
			case 'f':
			case 'F':
				digit = 15;
				break;
			default:
				printf("unexpected digit!\n");
				return -1;
				break;
		}
		val = val + digit;
		i++;
	}
	return val;
}



