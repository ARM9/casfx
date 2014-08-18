
.macro WaitForHblank
	.a8
	.local L0
L0:	lda f:REG_HVBJOY
	bit #$40
	beq L0
.endmacro

.macro ForceHaltGSU
	.a8
	lda f:GSU_SFR
	and #$DF
	sta f:GSU_SFR
.endmacro

;:	lda GSU_SFR ; wait for GSU operation to finnish
;	bit #$20
;	bne :-

.bss
	irq_flag:	.res 2

.code

.scope Interrupts
SetupIRQ:
	.a8
	.i16
	ldx #$0002 ; bottom irq
	stx irq_flag
	lda #$E0
	sta REG_HTIMEL
	lda #$CE
	sta REG_VTIMEL
	lda #$31	; HV-IRQ and autojoy enabled
	sta REG_NMITIMEN
	rts

irqRoutinesTable:
.addr ScreenTopIRQ
.addr ScreenEndIRQ

irqPositionTable:
.word $00E0, $00CE ; bottom irq timing
.word $00E0, $000E ; top irq timing

ScreenTopIRQ:
	sep #$30
	ldx inidisp_mirror ; #$0F
	WaitForHblank
	;.repeat 5
	;nop
	;nop
	;nop
	;.endrep ; About this many cycles left in hblank at this point, doubt waitforhblank is necessary
	stx REG_INIDISP

	phk
	plb
	
	rep #$30
	ldx irq_flag
	lda irqPositionTable,x
	sta f:REG_HTIMEL
	lda irqPositionTable+2,x
	sta f:REG_VTIMEL
	
	ldx #$0002
	stx irq_flag
	rts



ScreenEndIRQ:
	sep #$30
	ldx #$8F
	WaitForHblank
	stx REG_INIDISP
	
	rep #$30
	lda irq_flag
	asl
	tax
	lda irqPositionTable,x
	sta f:REG_HTIMEL
	lda irqPositionTable+2,x
	sta f:REG_VTIMEL
	
	ldx #$0000
	stx irq_flag
	
	sep #$20
	inc <frame_counter
	
	lda #$00
	pha
	plb
	
	jsr ChugFramebuffers
	
	lda f:parity	; Test our parity bit
	and #$CA
	lsr
	stz $2121
	sta $2122
	sta $2122
	
	rep #$20
	lda bg2_x
	inc a
	inc a
	sta bg2_x
	
	sep #$20
	sta REG_BG2HOFS
	xba
	sta REG_BG2HOFS
	
	rts

NMIHandler:
	; Using IRQ as an earlier NMI
IRQHandler:
	rep #$30
	pha
	lda f:REG_RDNMI ; read both nmi and irq flag
	bmi :+ ; See if IRQ was triggered by console
	lda f:GSU_SFR ; else clear gsu irq and do nothing in particular
	pla
	rtl
	
:	sei
	phb
	phx
	phy
	
	sep #$20
	lda #$00
	pha
	plb
	
	ldx irq_flag
	jsr (irqRoutinesTable,x)
;	lda #$40
;:	bit HVBJOY
;	beq :-
	
	rep #$30
	ply
	plx
	plb
	pla
	rtl
.endscope

.segment "BANK2"
;Interrupt vectors to be executed during 65816 operation in WRAM
DummyVectors:
	nop	;cop
	nop
	nop	;brk
	nop
	stp ;abort
	nop
	bra :+ ;NMI
	;nop
	nop ;unused
	nop
	;IRQ
	jsl $7E0000|.loword(Interrupts::IRQHandler)
	rti
:	jsl $7E0000|.loword(Interrupts::NMIHandler)	;nmi goes here
	rti
DummyVectorsSize = * - DummyVectors

