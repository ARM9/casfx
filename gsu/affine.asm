; -----------------------------------------------
; TODO: Fix everything
; -----------------------------------------------

.segment "BANK1"
;name:      rotate
;desc:      Rotate a sprite R3 degrees
;in:        Ry y (8.8), Rx x(8.8), R3 rotation
;clobber:   everything
Rotate1:
    ibt     R0, #^sin_lut
    romb
    iwt     R0, #sin_lut
    move    R14, R0
    with    R14
    add     R3
    ibt     Rtx, #64 ; cos offset
    
    to R5
    getbs ; load sine sin(R3)
    
    with R3
    add Rtx
    with R3
    lob
    add R3
    move R14, R0 ;done with R0
    
    to R3
    getbs ; load cosine cos(R3)
    
    ; set up gfx pointer
    ibt     R0, #^block_gfx
    romb
    iwt     R6, #block_gfx
    iwt     R9, #(block_gfx_size/4)
    iwt     Rloop, #@lop
    
    ;cache
@begin:
    ibt Rcount, #(block_gfx_size/8)
    
@lop:
        
        merge   ; R14 = Rty&0xff00 | (Rtx&0xff00)>>8
        add R6
        move R14, R0
        
        getc
        plot
        loop
        inc Rx
        
        ibt R0, #(block_gfx_size/4)
        with Rx
        sub R0
        
        dec R9
        bne @begin
        inc Ry
    
    ret
    nop
    

;name:      rotate
;desc:      Rotate a sprite R3 degrees (0.8 fixed)
;in:        Rty y (8.8), Rtx x(8.8), R3 rotation
;clobber:   everything
Rotate2:
    ibt     R0, #^sin_lut
    romb
    iwt     R0, #sin_lut
    move    R14, R0
    with    R14
    add     R3
    ibt     Rx, #64 ; cos offset
    
    to R5
    getbs ; load sine sin(R3)
    
    with R3
    add Rx
    with R3
    lob
    add R3
    move R14, R0 ;done with R0
    
    ibt R4, #<-8 ; load correction offset
    
    to R3
    getbs ; load cosine cos(R3)
    
    ; set up gfx pointer
    ibt     R0, #^block_gfx
    romb
    iwt     R6, #block_gfx
    iwt     R9, #(block_gfx_size/8)
    iwt     Rloop, #@lop
    
    ;cache
@begin:
    ;move Rx, Rtx
    ;move Ry, Rty
    ibt Rcount, #(block_gfx_size/8)
@lop:
        getc
        inc R14
        ;dX = (Y*sin(A)>>8) + (X*cos(A)>>8)
        ;dY = (Y*cos(A)>>8) - (X*sin(A)>>8)
        
        ;dX
        from Rty ; R0 = Y*sin(A)>>8
        mult R5
        hib
        
        from Rtx ; Rx = X*cos(A)>>8
        to Rx
        mult R3
        with Rx
        hib
        to Rx
        add Rx ; Rx = R0 + Rx
        
        ;dY
        from Rty ; R0 = Y*cos(A)>>8
        mult R3
        hib
        
        from Rtx ; Ry = X*sin(A)>>8
        to Ry
        mult R5
        with Ry
        hib
        to Ry
        sub Ry ; Ry = R0 - Ry
        
        with Rx
        add R4
        with Ry
        add R4
        
        inc Rtx
        loop
        plot
        
        ibt R0, #(block_gfx_size/8)
        with Rtx
        sub R0
        
        dec R9
        bne @begin
        inc Rty
    
    ret
    nop

dbg_BlockSize GSU_MainLoop
.include "sin_lut.asm"

