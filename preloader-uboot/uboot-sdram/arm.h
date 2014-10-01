
/* Interrupt stack setup by our interrupt handlers.
 * If the interrupt stack changes in startup.S then 
 * this structure needs to change as well. 
 */
typedef struct _interrupt_stack {
	uint32_t	r0;
	uint32_t	r1;
	uint32_t	r2;
	uint32_t	r3;
	uint32_t	r4;
	uint32_t	r5;
	uint32_t	r6;
	uint32_t	r7;
	uint32_t	r8;
	uint32_t	r9;
	uint32_t	r10;
	uint32_t	r11;
	uint32_t	r12;
	uint32_t	lr;
} interrupt_stack, *pinterrupt_stack;


/* Get ARM Vector base address register */
static inline volatile uint8_t __get_byte(volatile void *pbyte)
{
	uint8_t *p = (uint8_t *)pbyte;
	return *p;
}

/* Get ARM Vector base address register */
static inline volatile uint8_t __put_byte(volatile void *pbyte, uint8_t byte)
{
	uint8_t val;
	uint8_t *p = (uint8_t *)pbyte;
	*p = byte;
}

/* Get ARM Vector base address register */
static inline uint32_t __get_vbar(void)
{
    uint32_t val;
    __asm volatile("mrc p15, 0, %0, c12, c0, 0" : "=r" (val));
    return val;
}

/* Get ARM Vector base address register */
static inline uint32_t __get_cpuid(void)
{
    uint32_t val;
    __asm volatile("mrc p15, 0, %0, c0, c0, 5" : "=r" (val));
    return val;
}

/* Set ARM Vector base address register */
static inline void __set_vbar(uint32_t val)
{
    __asm volatile("mcr p15, 0, %0, c12, c0, 0\n"
		   : : [vbar] "r" (val) : );
}

static inline volatile uint32_t __get_dfar(void)
{
    uint32_t val;
    __asm volatile("mrc p15, 0, %0, c6, c0, 0" : "=r" (val));
    return val;
}

static inline void __set_dfar(uint32_t val)
{
    __asm volatile("mcr p15, 0, %0, c6, c0, 0\n"
		   : : [vbar] "r" (val) : );
}

// Data fault status register
// From ...
// http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0363e/BGBEDEIF.html
//
// 31-13 : Reserved
// 12    : SD, 0 = AXI decode caused the abort or reset value
//	 :     1 = AXI slave error caused the abort
// 11    : RW  0 = read access caused the abort, reset value
//	 :     1 = write access caused the abort
// 10    : S   Part of status field, see bits 3:0
// 9:8   :     Reserved
// 7:4   : Domain, indicates which domain caused the fault
// 3:0   : Fault Status, 10,3:0 are used - these
//	   are listed in priority order
//	   0b00001 - Alignment 
//	   0b00000 - Background
// 	   0b01101 - Permission
//         0b01000 - Precise external abort
//         0b10110 - Imprecise external abort
//         0b11001 - Precise Parity/ECC Error
//         0b11000 - Imprecise Parity/ECC Error
//         0b00010 - Debug event
//
static inline volatile uint32_t __get_dfstatus(void)
{
    uint32_t val;
    __asm("mrc p15, 0, %0, c5, c0, 0" : "=r" (val));
    return val;
}

static inline void __set_dfstatus(uint32_t val)
{
    __asm volatile("mcr p15, 0, %0, c5, c0, 0\n"
		   : : [vbar] "r" (val) : );
}

static inline uint32_t __get_sctrl(void)
{
    uint32_t val;
    __asm("MRC p15, 0, %0,    c1, c0, 0" : "=r" (val));
    return val;
}

static inline void __set_sctrl(uint32_t val)
{
    __asm("MCR p15, 0, %0,    c1, c0, 0" : : "r" (val));
}

static inline uint32_t __get_sp(void)
{
	uint32_t spreg=0xffffffff;
	__asm("mov %0, sp" : "=r"(spreg));
	return spreg;
}

static inline uint32_t __get_pc(void)
{
	uint32_t pcreg=0xffffffff;
	__asm("mov %0, pc" : "=r"(pcreg));
	return pcreg;
}

static inline uint32_t __get_cpsr(void)
{
	uint32_t cpsr=0xffffffff;
	__asm("mrs %0, cpsr" : "=r"(cpsr));
	return cpsr;
}

static inline uint32_t __set_cpsr(uint32_t cpsr)
{
	__asm("mrs cpsr, %0" : "=r"(cpsr));
}

extern _interrupts;

