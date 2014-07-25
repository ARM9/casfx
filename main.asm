
.include "header.inc"

.code
.include "debug.asm"
.include "snes_regs.asm"
.include "ppu.asm"
.include "mem.asm"
.include "interrupts.asm"
.include "framebuffer.asm"

.include "snes_init.asm"

.include "assets.asm"

;-------------------------------------------
.include "zpvars.asm"

.bss
	bg2_x: .res 2
	
	;ppu register mirrors
	inidisp_mirror:		.res 1
	
	;gsu register mirrors
	gsu_scmr_mirror:	.res 1
	

.segment "PRGRAM"
	WRAM_Prg: .res $8000

;-------------------------------------------
.code

Reset:
	init_snes

Entry:
	.a8
	.i16
	phk
	plb
	
	; Make a blank tile with colour $xF.
	; this is for the vertical screen borders,
	; SetupMap will use palette 4 and I made colour $4F black in colours.pal.
	rep #$30
	lda #$FFFF
	sta dp0
	sep #$20
	FillVRAM $7E0000, $2A00, $20
	FillVRAM $7E0000, $3000+$2A00, $20
	
	jsl SetupMap
	
	LoadPalette sfx_pal, 0, 512
	
	LoadBlockToWRAM $008000, WRAM_Prg, $8000
	LoadBlockToWRAM DummyVectors, $7E0104, DummyVectorsSize
	
	jml $7E0000|.loword(WRAM_Main)

WRAM_Main:
	.i16
	sep #$20
	lda #$5b
	sta f:parity

	; Initialize GSU
	lda #$01
	sta GSU_CLSR ; Set clock frequency to 21.4MHz
	
	lda #(GSU_CFGR_IRQ_MASK | GSU_CFGR_FASTMUL)
	sta GSU_CFGR ; Disable GSU IRQ
	
	lda #.loword(FRAMEBUFFER)>>10 ; Set screen base
	sta GSU_SCBR
	
	lda #(GSU_RON|GSU_RAN) | GSU_SCMR_4BPP | GSU_SCMR_H192 ;192px 4bpp give ROM and gamepak RAM access to GSU
	sta GSU_SCMR
	sta gsu_scmr_mirror
	
	stz GSU_RAMBR	; Set RAM bank to $70
	
	lda #^GSU_Entry
	sta GSU_PBR		; Program bank, works like scpu pbr
	
	rep #$30
	
	lda #.loword(GSU_Entry)
	sta GSU_R15		; GSU execution begins here
	
	sep #$20
	
	; Bare bones ppu settings for demo purposes
	lda #$02
	sta REG_BGMODE
	
	lda #(VRAM_FB_MAP >> 8) & $FC	; $2C
	sta REG_BG1SC
	lda #$73
	sta REG_BG2SC
	lda #$2F
	sta REG_BG3SC
	
	lda #$50
	sta REG_BG12NBA
	
	lda #$94
	sta REG_BG2VOFS
	stz REG_BG2VOFS
	
	lda #$01
	sta REG_TM
	
	; do some vsyncing
:	bit REG_HVBJOY
	bpl :-
:	bit REG_HVBJOY
	bmi :-
:	bit REG_HVBJOY
	bpl :-
	
	jsr Interrupts::SetupIRQ
	
	lda #$0F
	sta inidisp_mirror
	
	cli
	
@forever:
	wai
	
	bra @forever

.segment "BANK2"
; Todo: port to superfx maybe
.proc SetupMap
	php
	rep #$10
	sep #$20
	
	lda #$80
	sta $2115
	
	rep #$20
	lda #$2C00 ; Map address in vram
	sta $2116
	
	ldy #$400 ; map size in words
	lda #$02A1
:	sta $2118
	dey
	cpy #$3C0
	bne :-
	
	; vhopppcc cccccccc
	lda #$1400 ; start at tile 0, use palette 5
	sta dp0
	
	lda #$12A0 ; blank tile, pal 6
	sta dp1
	
@begin_fill:
	sta $2118
	dey
	sta $2118
	dey
	
	lda dp0
	ldx #28
:	sta $2118
	clc
	adc #24	; 28x24 tiles column major, 224x192 px
			; 28*24 = 672
	dey
	dex
	bne :-
	
	sec
	sbc #671
	sta dp0
	
	lda dp1
	
	sta $2118
	dey
	sta $2118
	dey
	
	cpy #$C1
	bcs @begin_fill
@end_fill:
	
	lda #$02A1
	;ldy #$C0
:	sta $2118
	dey
	bne :-
	
	plp
	rtl
.endproc

.include "gsu/gsu.asm"

