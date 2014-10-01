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
