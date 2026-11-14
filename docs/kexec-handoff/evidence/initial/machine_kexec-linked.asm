
out/kexec-boot-fix/build/vmlinux:	file format elf64-littleaarch64

Disassembly of section .text:

ffffffc080036308 <machine_kexec>:
ffffffc080036308:      	paciasp
ffffffc08003630c:      	stp	x29, x30, [sp, #-0x30]!
ffffffc080036310:      	stp	x22, x21, [sp, #0x10]
ffffffc080036314:      	stp	x20, x19, [sp, #0x20]
ffffffc080036318:      	mov	x29, sp
ffffffc08003631c:      	adrp	x8, 0xffffffc082381000 <posix_timers_hashtable+0x910>
ffffffc080036320:      	mov	x19, x0
ffffffc080036324:      	ldr	x21, [x8, #0x8e0]
ffffffc080036328:      	bl	0xffffffc08002a0c0 <cpus_are_stuck_in_kernel>
ffffffc08003632c:      	adrp	x22, 0xffffffc08214b000 <nf_conncount_locks+0x1c0>
ffffffc080036330:      	ldr	w2, [x22, #0x300]
ffffffc080036334:      	b	0xffffffc08003658c <machine_kexec+0x284>
ffffffc080036338:      	and	w20, w0, #0x1
ffffffc08003633c:      	nop
ffffffc080036340:      	mov	w3, wzr
ffffffc080036344:      	adrp	x0, 0xffffffc08164e000 <pty_line_name.ptychar+0x35718>
ffffffc080036348:      	add	x0, x0, #0x2b
ffffffc08003634c:      	mov	w1, w20
ffffffc080036350:      	bl	0xffffffc0810969e8 <_printk>
ffffffc080036354:      	ldr	x2, [x19]
ffffffc080036358:      	adrp	x8, 0xffffffc08162c000 <pty_line_name.ptychar+0x13718>
ffffffc08003635c:      	add	x8, x8, #0xe80
ffffffc080036360:      	adrp	x9, 0xffffffc081579000 <kallsyms_seqs_of_names+0x6d318>
ffffffc080036364:      	add	x9, x9, #0xef9
ffffffc080036368:      	ldr	x3, [x19, #0x18]
ffffffc08003636c:      	tst	x2, #0x4
ffffffc080036370:      	add	x4, x19, #0x288
ffffffc080036374:      	adrp	x0, 0xffffffc081579000 <kallsyms_seqs_of_names+0x6d318>
ffffffc080036378:      	add	x0, x0, #0xf02
ffffffc08003637c:      	csel	x1, x9, x8, eq
ffffffc080036380:      	bl	0xffffffc0810969e8 <_printk>
ffffffc080036384:      	b	0xffffffc080036598 <machine_kexec+0x290>
ffffffc080036388:      	mrs	x8, CurrentEL
ffffffc08003638c:      	cmp	x8, #0x8
ffffffc080036390:      	cset	w4, ne
ffffffc080036394:      	add	x1, x19, #0x290
ffffffc080036398:      	add	x2, x19, #0x2a0
ffffffc08003639c:      	add	x3, x19, #0x2a8
ffffffc0800363a0:      	adrp	x0, 0xffffffc08163d000 <pty_line_name.ptychar+0x24718>
ffffffc0800363a4:      	add	x0, x0, #0xa62
ffffffc0800363a8:      	bl	0xffffffc0810969e8 <_printk>
ffffffc0800363ac:      	cmp	x21, x19
ffffffc0800363b0:      	b.eq	0xffffffc0800363d4 <machine_kexec+0xcc>
ffffffc0800363b4:      	tbnz	w20, #0x0, 0xffffffc0800363d4 <machine_kexec+0xcc>
ffffffc0800363b8:      	ldr	w8, [x22, #0x300]
ffffffc0800363bc:      	cmp	w8, #0x1
ffffffc0800363c0:      	b.hi	0xffffffc0800365c0 <machine_kexec+0x2b8>
ffffffc0800363c4:      	cmp	x21, x19
ffffffc0800363c8:      	b.ne	0xffffffc0800363fc <machine_kexec+0xf4>
ffffffc0800363cc:      	tbz	w20, #0x0, 0xffffffc0800363f4 <machine_kexec+0xec>
ffffffc0800363d0:      	b	0xffffffc0800363fc <machine_kexec+0xf4>
ffffffc0800363d4:      	cmp	x21, x19
ffffffc0800363d8:      	b.ne	0xffffffc0800365c0 <machine_kexec+0x2b8>
ffffffc0800363dc:      	tbz	w20, #0x0, 0xffffffc0800363f4 <machine_kexec+0xec>
ffffffc0800363e0:      	adrp	x0, 0xffffffc081572000 <kallsyms_seqs_of_names+0x66318>
ffffffc0800363e4:      	add	x0, x0, #0x1d1
ffffffc0800363e8:      	bl	0xffffffc0800af5d8 <__warn_printk>
ffffffc0800363ec:      	brk	#0x800
ffffffc0800363f0:      	b	0xffffffc0800363fc <machine_kexec+0xf4>
ffffffc0800363f4:      	bl	0xffffffc08002a0a8 <smp_crash_stop_failed>
ffffffc0800363f8:      	tbnz	w0, #0x0, 0xffffffc0800363e0 <machine_kexec+0xd8>
ffffffc0800363fc:      	adrp	x0, 0xffffffc081592000 <note_page.units+0x1016b>
ffffffc080036400:      	add	x0, x0, #0x37a
ffffffc080036404:      	bl	0xffffffc0810969e8 <_printk>
ffffffc080036408:      	msr	DAIFSet, #0xf
ffffffc08003640c:      	ldrb	w8, [x19]
ffffffc080036410:      	tbnz	w8, #0x2, 0xffffffc0800364a0 <machine_kexec+0x198>
ffffffc080036414:      	b	0xffffffc0800365c4 <machine_kexec+0x2bc>
ffffffc080036418:      	mrs	x8, CurrentEL
ffffffc08003641c:      	cmp	x8, #0x8
ffffffc080036420:      	b.eq	0xffffffc08003642c <machine_kexec+0x124>
ffffffc080036424:      	ldr	x0, [x19, #0x298]
ffffffc080036428:      	bl	0xffffffc080023dc4 <__hyp_set_vectors>
ffffffc08003642c:      	adrp	x8, 0xffffffc081667000 <hmbird_sched_class+0x20>
ffffffc080036430:      	adrp	x10, 0xffffffc081d14000 <reserved_pg_dir>
ffffffc080036434:      	add	x10, x10, #0x0
ffffffc080036438:      	ldr	x9, [x8, #0x9b8]
ffffffc08003643c:      	ldr	x8, [x19, #0x2a0]
ffffffc080036440:      	sub	x10, x10, x9
ffffffc080036444:      	ldr	x9, [x19, #0x2c0]
ffffffc080036448:      	msr	TTBR0_EL1, x10
ffffffc08003644c:      	isb
ffffffc080036450:      	dsb	nshst
ffffffc080036454:      	tlbi	vmalle1
ffffffc080036458:      	nop
ffffffc08003645c:      	nop
ffffffc080036460:      	dsb	nsh
ffffffc080036464:      	isb
ffffffc080036468:      	mrs	x10, TCR_EL1
ffffffc08003646c:      	and	x11, x10, #0x3f
ffffffc080036470:      	cmp	x11, x9
ffffffc080036474:      	b.eq	0xffffffc080036488 <machine_kexec+0x180>
ffffffc080036478:      	and	x10, x10, #0xffffffffffffffc0
ffffffc08003647c:      	orr	x9, x10, x9
ffffffc080036480:      	msr	TCR_EL1, x9
ffffffc080036484:      	isb
ffffffc080036488:      	msr	TTBR0_EL1, x8
ffffffc08003648c:      	isb
ffffffc080036490:      	mov	x0, x19
ffffffc080036494:      	ldr	x8, [x19, #0x290]
ffffffc080036498:      	blr	x8
ffffffc08003649c:      	brk	#0x800
ffffffc0800364a0:      	adrp	x20, 0xffffffc081667000 <hmbird_sched_class+0x20>
ffffffc0800364a4:      	adrp	x9, 0xffffffc081d14000 <reserved_pg_dir>
ffffffc0800364a8:      	add	x9, x9, #0x0
ffffffc0800364ac:      	ldr	x8, [x20, #0x9b8]
ffffffc0800364b0:      	sub	x8, x9, x8
ffffffc0800364b4:      	msr	TTBR0_EL1, x8
ffffffc0800364b8:      	isb
ffffffc0800364bc:      	dsb	nshst
ffffffc0800364c0:      	tlbi	vmalle1
ffffffc0800364c4:      	nop
ffffffc0800364c8:      	nop
ffffffc0800364cc:      	dsb	nsh
ffffffc0800364d0:      	isb
ffffffc0800364d4:      	adrp	x8, 0xffffffc081667000 <hmbird_sched_class+0x20>
ffffffc0800364d8:      	ldrsw	x8, [x8, #0x9c4]
ffffffc0800364dc:      	mrs	x9, TCR_EL1
ffffffc0800364e0:      	and	x10, x9, #0x3f
ffffffc0800364e4:      	cmp	x10, x8
ffffffc0800364e8:      	b.eq	0xffffffc0800364fc <machine_kexec+0x1f4>
ffffffc0800364ec:      	and	x9, x9, #0xffffffffffffffc0
ffffffc0800364f0:      	orr	x8, x9, x8
ffffffc0800364f4:      	msr	TCR_EL1, x8
ffffffc0800364f8:      	isb
ffffffc0800364fc:      	adrp	x9, 0xffffffc081667000 <hmbird_sched_class+0x20>
ffffffc080036500:      	ldr	x8, [x20, #0x9b8]
ffffffc080036504:      	adrp	x11, 0xffffffc081d12000 <idmap_pg_dir>
ffffffc080036508:      	add	x11, x11, #0x0
ffffffc08003650c:      	ldr	x9, [x9, #0x900]
ffffffc080036510:      	adrp	x12, 0xffffffc081d15000 <swapper_pg_dir>
ffffffc080036514:      	add	x12, x12, #0x0
ffffffc080036518:      	add	x10, x8, x9
ffffffc08003651c:      	sub	x10, x11, x10
ffffffc080036520:      	orr	x11, x10, #0xffffff8000000000
ffffffc080036524:      	cmp	x11, x12
ffffffc080036528:      	b.ne	0xffffffc080036530 <machine_kexec+0x228>
ffffffc08003652c:      	brk	#0x800
ffffffc080036530:      	ubfx	x12, x10, #38, #1
ffffffc080036534:      	and	x10, x10, #0x7fffffffff
ffffffc080036538:      	sub	x8, x11, x8
ffffffc08003653c:      	add	x9, x10, x9
ffffffc080036540:      	adrp	x1, 0xffffffc082214000 <vmap_notify_list+0x30>
ffffffc080036544:      	add	x1, x1, #0x300
ffffffc080036548:      	cmp	x12, #0x0
ffffffc08003654c:      	csel	x0, x9, x8, eq
ffffffc080036550:      	bl	0xffffffc08003e0e4 <cpu_do_switch_mm>
ffffffc080036554:      	ldr	x8, [x20, #0x9b8]
ffffffc080036558:      	adrp	x9, 0xffffffc081d11000 <enter_vhe>
ffffffc08003655c:      	add	x9, x9, #0x6c
ffffffc080036560:      	sub	x8, x9, x8
ffffffc080036564:      	b	0xffffffc0800365e8 <machine_kexec+0x2e0>
ffffffc080036568:      	mrs	x9, CurrentEL
ffffffc08003656c:      	cmp	x9, #0x8
ffffffc080036570:      	cset	w0, ne
ffffffc080036574:      	ldr	x1, [x19, #0x18]
ffffffc080036578:      	ldr	x2, [x19, #0x288]
ffffffc08003657c:      	mov	x3, xzr
ffffffc080036580:      	mov	x4, xzr
ffffffc080036584:      	blr	x8
ffffffc080036588:      	brk	#0x800
ffffffc08003658c:      	brk	#0x800
ffffffc080036590:      	mov	w3, #0x1        // =1
ffffffc080036594:      	b	0xffffffc080036344 <machine_kexec+0x3c>
ffffffc080036598:      	adrp	x8, 0xffffffc082161000 <.compoundliteral.78+0x18>
ffffffc08003659c:      	add	x8, x8, #0x6c0
ffffffc0800365a0:      	mov	w4, wzr
ffffffc0800365a4:      	ldr	w9, [x8]
ffffffc0800365a8:      	cmp	w9, #0xe12
ffffffc0800365ac:      	b.ne	0xffffffc080036394 <machine_kexec+0x8c>
ffffffc0800365b0:      	ldr	w8, [x8, #0x4]
ffffffc0800365b4:      	cmp	w8, #0xe12
ffffffc0800365b8:      	b.eq	0xffffffc080036388 <machine_kexec+0x80>
ffffffc0800365bc:      	b	0xffffffc080036394 <machine_kexec+0x8c>
ffffffc0800365c0:      	brk	#0x800
ffffffc0800365c4:      	adrp	x8, 0xffffffc082161000 <.compoundliteral.78+0x18>
ffffffc0800365c8:      	add	x8, x8, #0x6c0
ffffffc0800365cc:      	ldr	w9, [x8]
ffffffc0800365d0:      	cmp	w9, #0xe12
ffffffc0800365d4:      	b.ne	0xffffffc08003642c <machine_kexec+0x124>
ffffffc0800365d8:      	ldr	w8, [x8, #0x4]
ffffffc0800365dc:      	cmp	w8, #0xe12
ffffffc0800365e0:      	b.eq	0xffffffc080036418 <machine_kexec+0x110>
ffffffc0800365e4:      	b	0xffffffc08003642c <machine_kexec+0x124>
ffffffc0800365e8:      	adrp	x9, 0xffffffc082161000 <.compoundliteral.78+0x18>
ffffffc0800365ec:      	add	x9, x9, #0x6c0
ffffffc0800365f0:      	mov	x0, xzr
ffffffc0800365f4:      	ldr	w10, [x9]
ffffffc0800365f8:      	cmp	w10, #0xe12
ffffffc0800365fc:      	b.ne	0xffffffc080036574 <machine_kexec+0x26c>
ffffffc080036600:      	ldr	w9, [x9, #0x4]
ffffffc080036604:      	cmp	w9, #0xe12
ffffffc080036608:      	b.eq	0xffffffc080036568 <machine_kexec+0x260>
ffffffc08003660c:      	b	0xffffffc080036574 <machine_kexec+0x26c>
