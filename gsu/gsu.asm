; -----------------------------------------------
; Some basic plotting routines to demonstrate GSU operation
; -----------------------------------------------

;GSU_INLINE = 1
.include "casfx.inc"


; Some alternative register names for clarity
gp0		= R0	;\ General purpose
gp1		= R3	;|pass arguments to functions in these four
gp2		= R5	;|
gp3		= R9	;/

Rx		= R1	; plot x pos
Ry		= R2	; plot y pos
Rmulr	= R4	; Lower 16 bit result of lmult
Rmul	= R6	; Multiplier for fmult and lmult
Rtx		= R7	; fixed point texel X position for merge
Rty		= R8	; fixed point texel Y position for merge
sp		= R10	; stack pointer PRESERVE
lr		= R11	; link register PRESERVE
Rcount	= R12	; loop count, hline length
Rloop	= R13	; loop address
Rrombuf	= R14	; rom buffer address register
pc		= R15	; program counter PRESERVE

.include "polygon.asm"

.segment "SRAM_ZP"
	

.segment "SRAM"
	displayList:
	myQuad:	.tag polygon
	myTri:	.tag polygon
	numPolygons = 2

.segment "BANK1"
;.listbytes	64

GSU_Entry:
	move sp,	#$2000	; Set up stack pointer
	move R14,	#$8000	; ROM address for GETxx instructions
	;ibt R0, #^GSU_Entry
	;romb
	
	lea		R9, displayList-2
	iwt		Rcount, #(.sizeof(polygon)*numPolygons)/2
	jal		BuildDisplayList
	nop
	
	cache
GSU_MainLoop:
	
	lm R0,	(framebuffer_status) ; Check if SCPU has finnished transfering the last framebuffer
	ror
	bcs		:+
	nop
		jal		ClearScreen
		sub R0
		
		ibt		R0,	#$0
		cmode
		
		lea		R9, myQuad
		jal		LoadPolygonData
		sub R0
		
		lms		Rx, (player_x)
		ibt		Ry, #20
		jal		DrawPolygon
		sub R0
		
		lea		R9, myTri
		jal		LoadPolygonData
		sub R0
		
		ibt		R0,	#$3
		cmode
		
		lms		Ry, (player_y)
		with	Ry
		add		#15
		jal		DrawPolygon
		sub R0
		
		lms		Rtx, (player_x)
		lms		Rty, (player_y)		
		jal		derp
		nop
		
		ibt		R0,	#$0
		cmode
		
		lms		Rx, (player_x)
		lms		Ry, (player_y)
		;jal		Rotate1
		sub R0
		
		ibt		Rty, #120
		lms		Rtx, (player_x)
		lms		R3, (player_rot)
		jal		Rotate2
		sub R0
		
		rpix
		
		stop
		nop
		
		bra		GSU_MainLoop
		nop
:	
	
	jal		Update
	nop
	
	stop
	nop
	bra		GSU_MainLoop
	nop
;.endproc

.proc Update
	lms		R0,	(player_rot)
	inc		R0
	lob
	sbk
	
	lms		R0, (player_x)
	inc		R0
	lob
	sbk
	
	lms		R0, (player_y)
	inc		R0
	lob
	ret
	sbk
	
.endproc

.proc ClearScreen
;Expects R0 = 0
	iwt R1, #.loword(FRAMEBUFFER)
	iwt Rcount, #$6000/2 ; real framebuffer size
	move Rloop, R15
@plotloop:
	stw (R1)
	inc R1
	loop
	inc R1
	
	ret
	nop
.endproc


.segment "SRAM_ZP"
	player_x:	.res 2
	player_y:	.res 2
	player_rot:	.res 2

.segment "BANK1"

Rx1		= R3	; top left x pos
Rx1inc	= R4	; top left x pos increment
Rx2		= R5	; top right x pos
Rx2inc	= R6	; top right x pos increment
Rdy		= R7	; trapezoid y height
Rdr		= R8	; rotation delta
Rcolor	= R9	; color counter

;Clobber: R9, R3, R4, R5, R6, R7
LoadPolygonData:
	;iwt		R0, #$0101
	movew	Rx1, (R9)
	from	Rx1
	to		Rx1inc
	hib
	;with Rx1
	;add R0
	;from Rx1
	;sbk
	with Rx1
	lob
	inc		R9
	inc		R9
	
	;iwt		R0, #$0101
	movew	Rx2, (R9)
	from	Rx2
	to		Rx2inc
	hib
	;with Rx2
	;sub R0
	;from Rx2
	;sbk
	with Rx2
	lob
	inc		R9
	inc		R9
	
	movew	Rdy, (R9)
	from	Rdy
	to		Rcolor
	hib
	with Rdy
	lob
	
	ret
	nop


DrawPolygon:
	from	Rcolor
	color
	
	iwt Rloop,	#@plotlop
	
	;cache
@hline1:
	from Rx1
	to Rx
	lob
	
	from Rx2
	lob
	to Rcount
	sub Rx
	bmi @hline3
	inc Rcount
	
@plotlop:
	loop
	plot
@hline3:
	with	Rx1
	add		Rx1inc
	
	with	Rx2
	add		Rx2inc
	
	dec Rdy
	bne @hline1
	inc Ry
	
	;rpix
	ret
	nop


.segment "BANK3"
poly_data:
cube_data:
	;Format:
	;	x1	x1inc
	;	x2	x2inc
	;	dy	color
	.byt	32, 0
	.byt	61, 0
	.byt	64, $0b
tri_data:
	.byt	64, 1
	.byt	128, <-1
	.byt	64, $02

.include "derp.asm"
.include "affine.asm"


.segment "BANK1"
; Since this is only called once we don't need to cache this
BuildDisplayList:
	;lea R9, $addr-2
	;iwt Rcount, #.sizeof(data) ;in words please
	ibt R0,		#^poly_data
	romb
	iwt R14,	#poly_data
	;cache
	move Rloop,	pc
@lop:
	getbl
	inc R14
	inc R9
	inc R9
	getbh
	inc R14
	loop
	stw (R9)
	
	ret
	nop
