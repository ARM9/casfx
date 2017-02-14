
; a bunch of nonsense
.include "casfx.inc"

.bss
ply: .res 5
lda: .res 4

.code

.define foo 5
bar = 66

iwt r5, #lda

main:
	iwt R10, #$2FE ; set up stack pointer
	ibt R1, #$FF
	jal setup

	;ibt r12, #$7F ; loop 127 times

	moveb (r11), r15
	iwt r13, #@loop
	lea r12, #@loop
	lea r12, @loop
@loop:
	loop

	bra @loop
	inc r1

setup:
	push r1
	push r11

	with r11
	add r10

	move r1, r11

	;pop r11, r1
	ret
	nop


	jal 1234
	ret
	push R0
	pop r15
	stop
	nop
	cache
	lsr
	rol

label:
	bra label
	bge label
	blt label
	bne label
	beq label
	bpl label
	bmi label
	bcc label
	bcs label
	bvc label
	bvs label

	to r0
	with r1
	stw (r2)
	loop
	alt1
	alt2
	alt3

	ldw (r3)
	plot
	swap
	color
	not
	add r4
	sub r5
	merge
	and r6

	mult r7
	sbk
	link #3
	sex
	asr
	ror
	jmp r8
	lob
	fmult
	ibt r9,#42
	from r10

	hib
	or r11
	inc r12
	getc
	dec r13
	getb
	iwt r14,#4242


	stb (r0)
	ldb (r0)
	rpix
	cmode
	adc r15
	sbc r0
	bic r1

	umult r2
	div2
	ljmp r8
	lmult
	lms r3,(42)
	xor r4
	getbh
	lm r5,(4242)


	add #5
	sub #6
	and #7
	mult #8
	sms (42),r6
	or #12
	ramb
	getbl
	sm (4242),r7

	adc #5
	cmp r8
	bic #7
	umult #8
	xor #12
	romb
	getbs


	move r9,r10
	moves r11,r12
	lea r13,4242
	move r14,#42
	move r15,#<-42
	move r0,#4242

    ; removed
	;move r1,(42)
	;move r2,(69)
	;move r3,(512)
	;move (42),r4
	;move (69),r5
	;move (512),r6

	moveb R0,(R8)
	moveb r8,(R9)
	moveb (R10),r0
	moveb (R11),r12

	movew r0,(r11)
	movew r14,(r11)
	movew (r1),r0
	movew (r2),r3

;	mjal 1234
;	mpush R0
;	mpush r15
;	mpop R15
;	mpop r0
;	mret
;
;	mstop
;	mnop
;	mcache
;	mlsr
;	mrol
;
;label:
;	mbra label
;	mbge label
;	mblt label
;	mbne label
;	mbeq label
;	mbpl label
;	mbmi label
;	mbcc label
;	mbcs label
;	mbvc label
;	mbvs label
;
;	mto r0
;	mwith r1
;	mstw (r2)
;	mloop
;	malt1
;	malt2
;	malt3
;
;	mldw (r3)
;	mplot
;	mswap
;	mcolor
;	mnot
;	madd r4
;	msub r5
;	mmerge
;	mand r6
;
;	mmult r7
;	msbk
;	mlink #3
;	msex
;	masr
;	mror
;	mjmp r8
;	mlob
;	mfmult
;	mibt r9,#42
;	mfrom r10
;
;	mhib
;	mor r11
;	minc r12
;	mgetc
;	mdec r13
;	mgetb
;	miwt r14,#4242
;
;
;	mstb (r0)
;	mldb (r0)
;	mrpix
;	mcmode
;	madc r15
;	msbc r0
;	mbic r1
;
;	mumult r2
;	mdiv2
;	mljmp r8
;	mlmult
;	mlms r3,(42)
;	mxor r4
;	mgetbh
;	mlm r5,(4242)
;
;
;	madd #5
;	msub #6
;	mand #7
;	mmult #8
;	msms (42),r6
;	mor #12
;	mramb
;	mgetbl
;	msm (4242),r7
;
;	madc #5
;	mcmp r8
;	mbic #7
;	mumult #8
;	mxor #12
;	mromb
;	mgetbs
;
;
;	move r9,r10
;	moves r11,r12
;	mlea r13,4242
;	move r14,#42
;	move r15,#<-42
;	move r0,#4242
;
;	move r1,(42)
;	move r2,(69)
;	move r3,(512)
;	move (42),r4
;	move (69),r5
;	move (512),r6
;
;	moveb R0,(R8)
;	moveb r8,(R9)
;	moveb (R10),r0
;	moveb (R11),r12
;
;	movew r0,(r11)
;	movew r14,(r11)
;	movew (r1),r0
;	movew (r2),r3
;

