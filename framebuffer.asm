
.bss	
	framebuffer_counter:	.res 1
	doublebuffer_index:		.res 2


.segment "SRAM" : far ; gsu ram
	;512 bytes direct page
	;512 bytes stack will have to suffice, no recursive function calls
	parity:		.res 2
	
	vbl_count:	.res 2
	
	framebuffer_status: .res 2
		;bit 0: set by SCPU, DMA of framebuffer to VRAM complete if set.
		;bit 1:
		;bit 2: 
		;bit 3: 
	FRAMEBUFFER_SIZE	= $5400 ; is actually $6100 (should be $6000?), need to limit plotting to $5400 by limiting x to 224
	FRAMEBUFFER			= $702000
	;.res ((256*194)/2)-FRAMEBUFFER_SIZE ; screen should be 256*192?? why is it taking the space of a 256*194 screen?
	;using SCBR $00, $6100 (add $400 per increment on SCBR) and onward looks safe, should probably limit plotting to $5400 bytes though.
	;$6000 should technically be safe but seems to plot past this by $100 bytes in some emulators (including bsnes, but not snes9x).
	;since the gsu thinks the screen is 256x192 ((256*192)/2 = $6000), it plots past the $5400 size of a 224x192 screen unless you limit X. Save sram or save cycles, choose wisely.
	;(256*194)/2 = $6100
	;plotting seems to wrap around to $CFF $2C00+6100 = $8D00, with SCBR $2C00.

;-------------------------------------------
.code

	VRAM_SCREEN1	= $0000
	VRAM_SCREEN2	= $3000
	VRAM_FB_MAP		= $2C00
	
ChugFramebuffers:
	.a8
	.i16
	lda #GSU_GO_BIT
:	bit GSU_SFR		; Wait until GSU has STOPed
	bne :-
	
	stz GSU_SCMR	; Take sram&rom bus access
	
	rep #$20
	lda f:vbl_count
	inc a
	sta f:vbl_count
	sep #$20
	
	ldy #.loword(FRAMEBUFFER_SIZE / 2)
	
	and #$01
	beq :+ ; branch on even frames
		;dma top of framebuffer
		ldx doublebuffer_index
		stx $2116	; Word address for accessing VRAM.
		lda #^FRAMEBUFFER
		ldx #.loword(FRAMEBUFFER)
		jsr DMAToVRAM
		lda f:framebuffer_status
		ora #1
		sta f:framebuffer_status
		
	bra @dma_fb_end
:		;dma bottom of framebuffer
		rep #$21
		lda doublebuffer_index
		adc #(FRAMEBUFFER_SIZE / 4)
		tax
		sep #$20
		stx $2116
		lda #^FRAMEBUFFER
		ldx #.loword(FRAMEBUFFER + (FRAMEBUFFER_SIZE / 2))
		jsr DMAToVRAM
		lda #0
		sta f:framebuffer_status
	
	lda framebuffer_counter
	and #$01
	beq :+ ; branch if framebuffer_counter is even, eg we're using SCREEN1 the next frame
	
		ldx #VRAM_SCREEN2
		stx doublebuffer_index
		lda #$50 | (VRAM_SCREEN1 >> 12)	; BG2 base is $50, unelegant approach but this is for demonstration purposes so gfdhsgf
		sta REG_BG12NBA
	
	bra @inc_fb_counter
:	
		ldx #VRAM_SCREEN1
		stx doublebuffer_index
		lda #$50 | (VRAM_SCREEN2 >> 12) ; 3
		sta REG_BG12NBA
	
@inc_fb_counter:
	inc framebuffer_counter ; increment when a new frame is displayed
@dma_fb_end:
	
	lda gsu_scmr_mirror
	;lda #$18|$21 ;RON+RAN | height + color mode GSU_SCREENMODE = $21
	sta GSU_SCMR
	
	lda GSU_SFR
	ora #<GSU_GO_BIT
	sta GSU_SFR
	
	rts

