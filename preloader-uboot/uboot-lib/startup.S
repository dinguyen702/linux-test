	.globl _start
_start:
	.globl _interrupts
_interrupts:
	b 	start_code	
	ldr	pc, _undefined_instruction
	ldr	pc, _software_interrupt
	ldr	pc, _prefetch_abort
	ldr	pc, _data_abort
	ldr	pc, _not_used
	ldr	pc, _irq
	ldr	pc, _fiq
 
_undefined_instruction:	.word undefined_instruction
_software_interrupt:	.word software_interrupt
_prefetch_abort:	.word prefetch_abort
_data_abort:		.word data_abort
_not_used:		.word not_used
_irq:			.word irq
_fiq:			.word fiq

	.global _end_ivt
_end_ivt:
	.balignl 16,0xdeadbeef

start_code:
	b	crt_startup 

	.align	5		
undefined_instruction:
	// not used! A placeholder for future improvement!
	bl	do_undefined_instruction

	.align	5		
software_interrupt:
	// not tested!
	sub	sp, sp, #4 		// leave room for spsr
	stmfd	sp!, {r0-r12,lr}	// store registers
	mov	r1, sp			// setup ptr to stack
	ldr	r0, [lr,#-4]		// load swi instruction
	bic	r0, r0, #0xff000000	// extract comment field
	mrs	r2, spsr		// get spsr
	str	r2, [sp,#14*4]		// store spsr onto stack
	
	bl	do_software_interrupt
	
	ldr	r2, [sp,#14*4]		// restore spsr
	msr	spsr, r2
	ldmfd	sp!, {r0-r12,lr}	// restore registers
	add	sp, sp, #4		// restore allocated space for spsr
	movs	pc, lr			// return from swi

	.align	5		
prefetch_abort:
	// not used! A placeholder for future improvement!
	bl	do_prefetch_abort

	.align	5		
data_abort:
	sub	sp, sp, #4 		// leave room for spsr
	stmfd	sp!, {r0-r12,lr}	// store registers
	mov	r0, sp			// Pass pointer to registers on stack to
					// Data abort handler
	mrs	r2, spsr		// get spsr
	str	r2, [sp,#14*4]		// store spsr onto stack
	
	bl	do_data_abort		// Branch with link to data abort handler
	
	ldr	r2, [sp,#14*4]		// restore spsr
	msr	spsr, r2
	ldmfd	sp!, {r0-r12,lr}	// restore registers
	add	sp, sp, #4		// restore allocated space for spsr
	subs	pc, lr, #6		// return from data abort handler, 
					// skipping instruction that caused
					// abort. Normally not a good thing, but
					// we're testing (and learning) in this case.
					// Note this assumes the instruction that caused the
					// data abort exception is two bytes.

	.align	5		
not_used:
	// not used! A placeholder for future improvement!
	bl	do_not_use

	.align	5		
irq:
	// not used! A placeholder for future improvement!
	bl	do_irq

	.align	5		
fiq:
	// not used! A placeholder for future improvement!
	bl	do_fiq


.globl __aeabi_uidivmod
__aeabi_uidivmod:
   stmfd   sp!, {r0, r1, ip, lr}
   bl   __aeabi_uidiv
   ldmfd   sp!, {r1, r2, ip, lr}
   mul   r3, r0, r2
   sub   r1, r1, r3
   mov   pc, lr





