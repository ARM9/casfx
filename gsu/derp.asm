; -----------------------------------------------
; Plot test
; -----------------------------------------------
.segment "BANK1"
.proc derp
;	in: Rtx x, Ry y
;	clobber: Ry
width	= R3
height	= R5
	
	from Rtx
	color
	
	;ibt Ry, #(192/2)-8
	iwt width,	#224
	ibt height,	#16
	iwt R13,	#@plotloop1
	
	;cache
@drawline:
	move Rcount, width
	ibt Rx,		#0
@plotloop1:
	loop
	plot
	
	dec height
	bne @drawline
	inc Ry
	
	ibt Ry,		#0
	ibt width,	#16
	iwt height,	#192
	iwt R13,	#@plotloop2
	
@draw_vertical_line:
	move Rcount, width
	move Rx, Rtx
	;iwt Rx, #224-16;(224/2)-8
@plotloop2:
	from Rx
	color
	loop
	plot

	dec height
	bne @draw_vertical_line
	inc Ry
	
	ret
	nop
.endproc
