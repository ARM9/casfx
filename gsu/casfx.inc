; Super Nintendo GSU (aka SuperFX) program assembly using ca65.
; by ARM9 - 2013

.ifndef _GSU_CPU_INC
_GSU_CPU_INC = 1

.setcpu "none"

.define _CASFX_ERR_STR "Invalid argument(s) for "

.macro _ASSERT_RANGE_ABS arg, _lower, _upper, err
    .assert _lower <= (arg) && (arg) <= _upper, error, err
.endmacro

.macro _ASSERT_RANGE_IMM arg, _lower, _upper, err
    .assert _lower <= .right(.tcount({arg})-1, {arg}) && .right(.tcount({arg})-1, {arg}) <= _upper, error, err
.endmacro

; **** Registers
.define r0      0  ; General purpose, default source/dest register
.define r1      1  ; Pixel plot X pos register
.define r2      2  ; Pixel plot Y pos register
.define r3      3  ; General purpose
.define r4      4  ; Lower 16 bit result of lmult
.define r5      5  ; General purpose
.define r6      6  ; Multiplier for fmult and lmult
.define r7      7  ; Fixed point texel X position for merge
.define r8      8  ; Fixed point texel Y position for merge
.define r9      9  ; General purpose
.define r10     10 ; General purpose (conventionally stack pointer)
.define r11     11 ; Return addres set by link
.define r12     12 ; Loop counter
.define r13     13 ; Loop point address
.define r14     14 ; ROM buffer address
.define r15     15 ; Program counter
.define R0      0
.define R1      1
.define R2      2
.define R3      3
.define R4      4
.define R5      5
.define R6      6
.define R7      7
.define R8      8
.define R9      9
.define R10     10
.define R11     11
.define R12     12
.define R13     13
.define R14     14
.define R15     15

.define sp      r10
.define pc      r15
.define SP      r10
.define PC      r15

.define _alt1_op    $3D
.define _alt2_op    $3E
.define _alt3_op    $3F

.macro _op_implied op,alt
    .if .tcount({alt}) = 1
        .assert _alt1_op <= alt && alt <= _alt3_op, error, "Invalid alt mode"
        .byte alt
    .endif
    .byte op
.endmacro

.define alt1   _op_implied $3D,
.define alt2   _op_implied $3E,
.define alt3   _op_implied $3F,

.macro _op16_one_reg op, err, reg
    ; Rn
    _ASSERT_RANGE_ABS reg, r0, r15, .concat (_CASFX_ERR_STR,err," Rn; R0-R15")
    .byte (op+reg)
    .exitmacro
.endmacro

.define to     _op16_one_reg $10,"TO",
.define with   _op16_one_reg $20,"WITH", ; Sets B flag which interacts with TO or FROM to form MOVE Rn, Rn' or MOVES Rn, Rn' respectively
.define from   _op16_one_reg $B0,"FROM",

.macro _op16_arith_one_arg op, alt, err, arg
    .if .xmatch (.left (1, {arg}), #) ; #n
        _ASSERT_RANGE_IMM {arg}, 0, 15, .concat (_CASFX_ERR_STR,err," #n; #0-15")
        ; alt3 for adc, umult
        ; alt2 for add, sub, mult
        .if .xmatch ({err}, {"ADC"}) || .xmatch ({err}, {"UMULT"})
            alt3
        .elseif .xmatch ({err}, {"CMP"}) || .xmatch ({err}, {"SBC"})
            .assert 0, error, .concat("Immediate value not allowed for opcode ",err," Rn; R0-R15")
        .else
            alt2
        .endif
        .byte op + .right(.tcount({arg})-1, {arg})
        .exitmacro
    .endif
    _ASSERT_RANGE_ABS arg, r0, r15, .concat (_CASFX_ERR_STR,err," Rn; R0-R15")
    .if .xmatch ({err}, {"CMP"}); cmp Rn
        alt3
        .byte (op+arg)
        .exitmacro
    .endif
    ; op Rn but not cmp
    .if .tcount({alt}) = 1
        alt1
    .endif
    .byte (op+arg)
.endmacro

; Rn or #n
.define madd    _op16_arith_one_arg $50,,"ADD",
.define madc    _op16_arith_one_arg $50,_alt1_op,"ADC",
.define msub    _op16_arith_one_arg $60,,"SUB",
.define msbc    _op16_arith_one_arg $60,_alt1_op,"SBC",
.define mcmp    _op16_arith_one_arg $60,_alt3_op,"CMP",

.define mmult   _op16_arith_one_arg $80,,"MULT",
.define mumult  _op16_arith_one_arg $80,_alt1_op,"UMULT",

; mult_r no alt, mult_i alt2, umult_r alt1, umult_i alt3

.macro _op15h_one_arg op, alt, err, arg
    .if .xmatch ({.left (1, {arg})}, #) ; #n
        _ASSERT_RANGE_IMM arg, 1, 15, .concat (_CASFX_ERR_STR,err," #n; #1-15")
        ; alt2 for and, or
        ; alt3 for bic, xor
        .if .tcount({alt}) = 1
            alt3
        .else
            alt2
        .endif
        .byte op + .right(.tcount({arg})-1, {arg}) - 1
        .exitmacro
    .else ; Rn
        _ASSERT_RANGE_ABS arg, r1, r15, .concat (_CASFX_ERR_STR,err," Rn; R1-R15")
        ; no alt for and, or
        ; alt1 for bic, xor
        .if .tcount({alt}) = 1
            alt1
        .endif
    .endif
    .byte op+(arg-1)
    ;.exitmacro
    ;.assert 0, error, .concat(_CASFX_ERR_STR,err,";")
.endmacro

.define mand    _op15h_one_arg $71,,"AND",
.define mbic    _op15h_one_arg $71,_alt1_op,"BIC",
.define mor     _op15h_one_arg $C1,,"OR",
.define mxor    _op15h_one_arg $C1,_alt1_op,"XOR",

.macro _op15l_one_reg op, err, reg
    _ASSERT_RANGE_ABS reg, r0, r14, .concat (_CASFX_ERR_STR,err," Rn; R0-R14")
    .byte op+reg
.endmacro

.define inc     _op15l_one_reg $D0,"INC",
.define dec     _op15l_one_reg $E0,"DEC",

.macro _op12_one_reg_indirect op, alt, err, reg
    .if .xmatch ({.left (1, {reg})}, {(})
        .if .xmatch ({.right (1, {reg})}, {)})
            _ASSERT_RANGE_ABS reg, r0, r11, .concat (_CASFX_ERR_STR,err," (Rm); (R0-R11)")
            .if .tcount({alt}) = 1
                .byte alt
            .endif
            .byte (op+reg)
            .exitmacro
        .endif
    .endif
    .assert 0, error, .concat(_CASFX_ERR_STR,err," (Rm); (R0-R11)")
.endmacro

.define stw     _op12_one_reg_indirect $30,,"STW",
.define stb     _op12_one_reg_indirect $30,_alt1_op,"STB",
.define ldw     _op12_one_reg_indirect $40,,"LDW",
.define ldb     _op12_one_reg_indirect $40,_alt1_op,"LDB",

.macro _op16_one_reg_one_imm op, range, name, err, reg, arg
    _ASSERT_RANGE_ABS reg, r0, r15, .concat (_CASFX_ERR_STR,name,err)
    .byte (op+reg)
    .if .xmatch (.left(1, {arg}), #)
        ; Only range check ibt, automatically clip iwt with .loword
        .if range <= $FF
            _ASSERT_RANGE_IMM arg, 0, range, .concat (_CASFX_ERR_STR,name,err)
            .byte .right(.tcount({arg})-1, {arg})
        .else
            .word .loword(.right(.tcount({arg})-1, {arg}))
        .endif
        .exitmacro
    .endif
    .if .xmatch ({name}, {"LEA"})
        ;_ASSERT_RANGE_ABS arg, 0, range, .concat (_CASFX_ERR_STR,name,err)
        .word .loword(arg)
        .exitmacro
        ; interesting quirk about how ca65 handles immediate #xyz data: lea r5, #$beef todo find out why this works
    .endif
    .assert 0, error, .concat(_CASFX_ERR_STR,name,err)
.endmacro

.define ibt    _op16_one_reg_one_imm $A0,$FF,"IBT"," Rn, #pp; R0-R15, #0-$FF",
.define iwt    _op16_one_reg_one_imm $F0,$FFFF,"IWT"," Rn, #xxxx; R0-R15, #0-$FFFF",
.define lea    _op16_one_reg_one_imm $F0,$FFFF,"LEA"," Rn, xxxx; R0-R15, 0-$FFFF",


.macro _op16_two_args op, alt, range, name, err, arg1, arg2
    .byte alt
    .if .xmatch (.left (1, {arg1}), {(}) ; SM or SMS
        .if .xmatch (.left (1, {arg2}), {(})
            .assert 0, error, .concat (_CASFX_ERR_STR,name,err)
        .endif
        _ASSERT_RANGE_ABS arg2, r0, r15, .concat (_CASFX_ERR_STR,name,err)
        _ASSERT_RANGE_ABS .loword(arg1), 0, range, .concat (_CASFX_ERR_STR,name,err)

        .if .xmatch ({name}, {"SM"})
            .byte (op+arg2)
            .word .loword(arg1)
            .exitmacro
        .elseif .xmatch ({name}, {"SMS"})
            .assert (arg1 & 1) <> 1, error, .concat("Operand (yy) must be even: ",name,err)
            .byte (op+arg2)
            .byte <(arg1>>1)
            .exitmacro
        .endif
        .assert 0, error, .concat (_CASFX_ERR_STR,name,err) ; this might not be necessary
    .elseif .xmatch (.left (1, {arg2}), {(}) ; LM or LMS
        _ASSERT_RANGE_ABS arg1, r0, r15, .concat (_CASFX_ERR_STR,name,err)
        _ASSERT_RANGE_ABS .loword(arg2), 0, range, .concat (_CASFX_ERR_STR,name,err)
        .if .xmatch ({name}, {"LM"})
            .byte (op+arg1)
            .word .loword(arg2)
            .exitmacro
        .elseif .xmatch ({name}, {"LMS"})
            .assert (arg2 & 1) <> 1, error, .concat("Operand (yy) must be even: ",name,err)
            .byte (op+arg1)
            .byte <(arg2>>1)
            .exitmacro
        .endif
    .endif
    .assert 0, error, .concat (_CASFX_ERR_STR,name,err)
.endmacro

; When the value of xx is odd, (xx-1) is loaded to the high byte.
.define lm     _op16_two_args $F0,_alt1_op, $FFFF, "LM", " Rn, (xx); R0-R15, (0-$FFFF)", ; Load memory
.define lms    _op16_two_args $A0,_alt1_op, 510, "LMS", " Rn, (yy); R0-R15, (0-510)", ; Load memory short address
.define sm     _op16_two_args $F0,_alt2_op, $FFFF, "SM", " (xx), Rn; (0-$FFFF), R0-R15", ; Store memory
.define sms    _op16_two_args $A0,_alt2_op, 510, "SMS", " (yy), Rn; (0-510), R0-R15", ; Store memory short address

.macro _op4_one_arg op, err, arg
    .if .xmatch ({.left (1, {arg})}, #) ; #n
        _ASSERT_RANGE_IMM arg, 1, 4, .concat (_CASFX_ERR_STR,err," #n; #1-4")
        .byte op + .right(.tcount({arg})-1, {arg}) - 1
    .else
        .assert 0, error, .concat (_CASFX_ERR_STR,err," #n; #1-4")
    .endif
.endmacro

.define link   _op4_one_arg $91,"LINK",

.macro _op6_one_reg op, alt, err, arg
    _ASSERT_RANGE_ABS arg, r8, r13, .concat (_CASFX_ERR_STR,err," Rn; R8-R13")
    .if .tcount ({alt}) = 1
        .byte alt
    .endif
    .byte op+(arg-8)
.endmacro

.define jmp    _op6_one_reg $98,,"JMP",
.define ljmp   _op6_one_reg $98,_alt1_op,"LJMP",


; **** Branch

.macro _branch_offset instr, target
    .local @distance, @next
    @distance = (target) - @next
    instr
    .assert @distance >= -128 && @distance <= 127, error, "Branch out of range"
    .byte <@distance
@next:
.endmacro

.macro _op_branch inst, target
    _branch_offset {.byte inst}, target
.endmacro


.define bra     _op_branch $05, ; target
.define bge     _op_branch $06, ; target
.define blt     _op_branch $07, ; target
.define bne     _op_branch $08, ; target
.define beq     _op_branch $09, ; target
.define bpl     _op_branch $0A, ; target
.define bmi     _op_branch $0B, ; target
.define bcc     _op_branch $0C, ; target
.define bcs     _op_branch $0D, ; target
.define bvc     _op_branch $0E, ; target
.define bvs     _op_branch $0F, ; target

; **** Implied

.define stop    _op_implied $00, ; Sends IRQ signal
.define nop     _op_implied $01, ; Clears alt1, alt2 and B flags
.define cache   _op_implied $02, ; If CBR != R15&$FFF0 then set CBR to R15&$FFF0 and clear all cache flags
.define mlsr    _op_implied $03,
.define mrol    _op_implied $04,

.define loop    _op_implied $3C, ; if(--r12 != 0) then R15 = R13

.define mplot   _op_implied $4C,
.define mrpix   _op_implied $4C,_alt1_op
.define mcolor  _op_implied $4E,
.define mcmode  _op_implied $4E,_alt1_op
.define mswap   _op_implied $4D,
.define mnot    _op_implied $4F,

.define mmerge  _op_implied $70,

.define msbk    _op_implied $90,
.define msex    _op_implied $95,
.define mdiv2   _op_implied $96,_alt1_op
.define masr    _op_implied $96,
.define mror    _op_implied $97,
.define mlob    _op_implied $9E,
.define mfmult  _op_implied $9F,
.define mlmult  _op_implied $9F,_alt1_op

.define mhib    _op_implied $C0,

.define getc    _op_implied $DF,
.define mramb   _op_implied $DF,_alt2_op
.define mromb   _op_implied $DF,_alt3_op

.define mgetb   _op_implied $EF,
.define mgetbh  _op_implied $EF,_alt1_op
.define mgetbl  _op_implied $EF,_alt2_op
.define mgetbs  _op_implied $EF,_alt3_op


; **** Pseudo-op moves

; WARNING TODO FIXME moveb and movew (Rm), Rn and (xx), Rn are ambiguous,
; unsure how to fix, thus I've omitted support for (xx). just use lm/sm/sms/lms
.macro _move_pseudo_op name, arg1, arg2
    .if .xmatch (.left (1, {arg1}), {(})
        .if .xmatch (.left (1, {arg2}), {(})
            ;move (var), (r8) is not a valid pseudo-op, nor is move (r8), (var)
            ;.assert 0, error, .concat(_CASFX_ERR_STR,name,";")
            .assert 0, error, .concat(_CASFX_ERR_STR, name, "; move (a), (b) is not a valid pseudo-op")
        .endif
        .if .xmatch ({name}, {"MOVEB"})
            _ASSERT_RANGE_ABS arg1, r0, r11, .concat (_CASFX_ERR_STR,name," (Rm), Rn; (R0-R11), R1-R15")
            _ASSERT_RANGE_ABS arg2, r0, r15, .concat (_CASFX_ERR_STR,name," (Rm), Rn; (R0-R11), R1-R15")
            .if (arg2 <> 0)
                with arg2
            .endif
            stb arg1
            .exitmacro
        .elseif .xmatch ({name}, {"MOVEW"})
            _ASSERT_RANGE_ABS arg1, r0, r11, .concat (_CASFX_ERR_STR,name," (Rm), Rn; (R0-R11), R0-R15")
            _ASSERT_RANGE_ABS arg2, r0, r15, .concat (_CASFX_ERR_STR,name," (Rm), Rn; (R0-R11), R0-R15")
            .if (arg2 <> 0)
                with arg2
            .endif
            stw arg1
            .exitmacro
        .endif

        ;_ASSERT_RANGE_ABS arg1, 0, $FFFF, .concat (_CASFX_ERR_STR,name," (xx), Rn; (0-$FFFF), R0-R15")
        ;_ASSERT_RANGE_ABS arg2, r0, r15, .concat (_CASFX_ERR_STR,name," (xx), Rn; (0-$FFFF), R0-R15")
        ;;move (xx), Sreg
        ;.if (arg1 <= $1FE) && ((arg1 & 1) <> 1) ; Can't delay if else evaluation until link stage, fudgesicle.
            ;sms arg1, arg2
        ;.else
            ;sm arg1, arg2
        ;.endif
        ;.exitmacro
        .assert 0, error, .concat(_CASFX_ERR_STR, name, ";")
    .elseif .xmatch (.left (1, {arg2}), {(})

        .if .xmatch ({name}, {"MOVEB"})
            _ASSERT_RANGE_ABS arg1, r0, r15, .concat (_CASFX_ERR_STR,name," Rn, (Rm); R0-R15, (R0-R11)")
            _ASSERT_RANGE_ABS arg2, r0, r11, .concat (_CASFX_ERR_STR,name," Rn, (Rm); R0-R15, (R0-R11)")
            .if (arg1 <> 0)
                with arg1
            .endif
            ldb arg2
            .exitmacro
        .elseif .xmatch ({name}, {"MOVEW"})
            _ASSERT_RANGE_ABS arg1, r0, r15, .concat (_CASFX_ERR_STR,name," Rn, (Rm); R0-R15, (R0-R11)")
            _ASSERT_RANGE_ABS arg2, r0, r11, .concat (_CASFX_ERR_STR,name," Rn, (Rm); R0-R15, (R0-R11)")
            .if (arg1 <> 0)
                with arg1
            .endif
            ldw arg2
            .exitmacro
        .endif

                ;_ASSERT_RANGE_ABS arg1, r0, r15, .concat (_CASFX_ERR_STR,name," Rn, (xx); R0-R15, (0-$FFFF)")
                ;_ASSERT_RANGE_ABS arg2, 0, $FFFF, .concat (_CASFX_ERR_STR,name," Rn, (xx); R0-R15, (0-$FFFF)")
        ;;move Dreg, (xx)
        ;.if (arg2 <= $1FE) && ((arg2 & 1) <> 1)
            ;lms arg1, arg2 ; lms Rn, (yy)
        ;.else
            ;lm arg1, arg2 ; lm Rn, (xx)
        ;.endif
        ;.exitmacro
        .assert 0, error, .concat(_CASFX_ERR_STR, name, ";")
    .elseif .xmatch (.left (1, {arg2}), #)
        .if .not .xmatch ({name}, {"MOVE"})
            .assert 0, error, .concat(_CASFX_ERR_STR,name,";")
        .endif
        _ASSERT_RANGE_ABS arg1, r0, r15, .concat (_CASFX_ERR_STR,name," Rn, #xx; R0-R15, #0-$FFFF")
        _ASSERT_RANGE_IMM arg2, 0, $FFFF, .concat (_CASFX_ERR_STR,name," Rn, #xx; R0-R15, #0-$FFFF")
        .if .right(.tcount({arg2})-1, {arg2}) <= $FF
            ibt arg1, arg2
        .else
            iwt arg1, arg2
        .endif
        .exitmacro
    .endif
    .if .not .xmatch ({name}, {"MOVE"})
        .assert 0, error, .concat(_CASFX_ERR_STR,name,"; Did you mean ",name," Rn, (Rm) or (Rm), Rn?")
    .endif
    _ASSERT_RANGE_ABS arg1, r0, r15, .concat (_CASFX_ERR_STR,name," Sreg, Dreg; R0-R15, R0-R15")
    _ASSERT_RANGE_ABS arg2, r0, r15, .concat (_CASFX_ERR_STR,name," Sreg, Dreg; R0-R15, R0-R15")
    ; move Dreg, Sreg
    with arg2
    to arg1
.endmacro

.define move    _move_pseudo_op "MOVE",
.define moveb   _move_pseudo_op "MOVEB",
.define movew   _move_pseudo_op "MOVEW",

; move Rn, #pp = ibt, move Rn, #xxxx = iwt
; moves R1, R2: R2 -> R1 and sets flags accordingly

.macro moves dreg, sreg
    _ASSERT_RANGE_ABS dreg, r0, r15, .concat (_CASFX_ERR_STR,"MOVES Dreg, Sreg; R0-R15, R0-R15")
    _ASSERT_RANGE_ABS sreg, r0, r15, .concat (_CASFX_ERR_STR,"MOVES Dreg, Sreg; R0-R15, R0-R15")
    .if .xmatch (.left (1, {dreg} ), {(}) || .xmatch (.left (1, {sreg}), {(})
        .assert 0, error, .concat(_CASFX_ERR_STR,"MOVES Dreg, Sreg; R0-R15, R0-R15")
    .endif
    with dreg
    from sreg
    .exitmacro
.endmacro


; Custom pseudo-op macros

; Stack push/pop pseudo-ops, empty descending
; empty descending/ascending allows `pop r15` sub return
; empty also gives you one empty word on stack, allowing stw/ldw (r10) without
; any additional inc/dec.
; full allows accessing top element of stack with just one load/store after push

.macro push reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7, reg8, reg9, reg10, reg11, reg12, reg13, reg14, reg15
    .ifnblank reg0
        movew (R10), reg0
        dec R10
        dec R10
        push reg1, reg2, reg3, reg4, reg5, reg6, reg7, reg8, reg9, reg10, reg11, reg12, reg13, reg14, reg15
    .endif
.endmacro

.macro pop reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7, reg8, reg9, reg10, reg11, reg12, reg13, reg14, reg15
    .ifnblank reg0
        .ifnblank reg1
            .assert reg0 <> r15, error, "R15 not in tail position for POP!!"
        .endif
        inc R10
        inc R10
        movew reg0, (R10)
        pop reg1, reg2, reg3, reg4, reg5, reg6, reg7, reg8, reg9, reg10, reg11, reg12, reg13, reg14, reg15
        .if reg0 = r15 && .defined(::_CASFX_AUTO_NOP)
            nop
        .endif
    .endif
.endmacro

; byte version of stm/ldm seems unnecessary
.macro pushb r
    moveb (R10), r
    dec R10
.endmacro

.macro popb r
    .assert r <> r15, warning, "Are you sure you want to pop a byte into r15?"
    inc R10
    moveb r, (R10)
.endmacro


; jump and link
.macro jal dest ; Modifies r11 and r15
    ; TODO possible to do linktime assertion?
    ;.assert .loword(dest) <= $FFFF, error, .sprintf("Address %d out of range (jal 0-$FFFF)", dest)
    link #4
    iwt R15, #dest
    .ifdef ::_CASFX_AUTO_NOP
        nop
    .endif
.endmacro

.macro ret
    jmp r11
    .ifdef ::_CASFX_AUTO_NOP
        nop
    .endif
.endmacro

; Automatically place nop instruction after `jal`,`ret` and `pop [..,]r15` pseudo ops
.macro autonop
    ::_CASFX_AUTO_NOP = 1
.endmacro

; Warn if cache base register is not aligned to, or sufficiently close to, 16bit boundary
.macro CacheWarn
    cache
    ;           set granularity, 0..x
    .assert *&$F < 4, warning, .sprintf("Cache base not aligned to 16 bit boundary")
.endmac

;.macro jsl dest
;;   .assert dest <= $FFFFFF, error, "Address out of range (jsl $00-FF:0000-FFFF)"
;   ibt R0, #^dest
;   iwt R11, #dest&$FFFF
;   ;with R0
;   ljmp R11
;.endmacro

;.repeat 16, i
;   .if .xmatch({val}, .ident(.sprintf("r%d", i)))
;       .byte op + i,
;   .endif
;.endrepeat

.macro _pseudo_op_3args op, a0, a1, a2
    .ifblank a2
        .ifblank a1
            .assert .paramcount > 1, error, "At least one operand required"
            op a0
        .else
            .if a0 <> r0
            with a0
            .endif
            op a1
        .endif
    .else
        .if a0 = a1 && a0 <> r0
            with a0
        .else
            .if a0 <> r0
            to a0
            .endif
            .if a1 <> r0
            from a1
            .endif
        .endif
        op a2
    .endif
.endmac

.define adc     _pseudo_op_3args {madc},
.define add     _pseudo_op_3args {madd},
.define sub     _pseudo_op_3args {msub},
.define sbc     _pseudo_op_3args {msbc},
.define cmp     _pseudo_op_3args {mcmp},
.define mult    _pseudo_op_3args {mmult},
.define umult   _pseudo_op_3args {mumult},

.define and     _pseudo_op_3args {mand},
.define bic     _pseudo_op_3args {mbic},
.define or      _pseudo_op_3args {mor},
.define xor     _pseudo_op_3args {mxor},

.macro _pseudo_op_2args op, a0, a1
    .ifblank a1
        .ifnblank a0
            .if a0 <> r0
            with a0
            .endif
        .endif
    .else
        .if a0 = a1 && a0 <> r0
            with a0
        .else
            .if a0 <> r0
            to a0
            .endif
            .if a1 <> r0
            from a1
            .endif
        .endif
    .endif
    op
.endmac

.define asr     _pseudo_op_2args {masr},
.define div2    _pseudo_op_2args {mdiv2},
.define hib     _pseudo_op_2args {mhib},
.define lob     _pseudo_op_2args {mlob},
.define lsr     _pseudo_op_2args {mlsr},
.define not     _pseudo_op_2args {mnot},
.define rol     _pseudo_op_2args {mrol},
.define ror     _pseudo_op_2args {mror},
.define sex     _pseudo_op_2args {msex},
.define swap    _pseudo_op_2args {mswap},

.macro _pseudo_op_1arg op, a0
    .ifnblank a0
        .if a0 <> r0
        with a0
        .endif
    .endif
    op
.endmac

.define cmode   _pseudo_op_1arg {mcmode},
.define color   _pseudo_op_1arg {mcolor},
.define ramb    _pseudo_op_1arg {mramb},
.define romb    _pseudo_op_1arg {mromb},
.define rpix    _pseudo_op_1arg {mrpix},
.define sbk     _pseudo_op_1arg {msbk},

.define getb    _pseudo_op_1arg {mgetb},
.define getbh   _pseudo_op_1arg {mgetbh},
.define getbl   _pseudo_op_1arg {mgetbl},
.define getbs   _pseudo_op_1arg {mgetbs},

; fmult a0 -> with a0; fmult
; fmult a0, a1, a2 -> to a0; from (a1==r6?a2:a1); fmult
.macro fmult a0, a1, a2
    .ifnblank a0
        .assert a0 <> r4, error, .concat(_CASFX_ERR_STR, "FMULT: destination register can't be R4")
        .ifnblank a1
            .ifnblank a2
                .assert a1 = r6 || a2 = r6, error, .concat(_CASFX_ERR_STR, "FMULT: at least one source register must be R6")

                .if a1 = r6
                    .if a0 = a2
                        .if a0 <> r0
                            with a0
                        .endif
                    .else
                        .if a0 <> r0
                            to a0
                        .endif
                        .if a2 <> r0
                            from a2
                        .endif
                    .endif
                .else
                    .if a0 = a1
                        .if a0 <> r0
                            with a0
                        .endif
                    .else
                        .if a0 <> r0
                            to a0
                        .endif
                        .if a1 <> r0
                            from a1
                        .endif
                    .endif
                .endif
            .else
                .assert a1 = r6 , error, .concat(_CASFX_ERR_STR, "FMULT: at least one source register must be R6")
                .if a0 <> r0
                with a0
                .endif
            .endif
        .else
            .if a0 <> r0
            with a0
            .endif
        .endif
    .endif
    mfmult
.endmac

; lmult a0 -> with a0; lmult
; lmult a0, r4, a2, a3 -> to a0; from (a2==r6?a3:a2); lmult
.macro lmult a0, a1, a2, a3
    .assert .paramcount <> 2 && .paramcount <> 3, error, .concat(_CASFX_ERR_STR, "LMULT: 0, 1, or 4 operands please")

    .ifnblank a0
        .assert a0 <> r4, error, .concat(_CASFX_ERR_STR, "LMULT: high destination register can't be R4")
        .ifnblank a1
            .assert a1 = r4, error, .concat(_CASFX_ERR_STR, "LMULT: low destination register must be R4")
            .ifnblank a3
                .if a3 = r6
                    .if a0 = a2
                        .if a0 <> r0
                            with a0
                        .endif
                    .else
                        .if a0 <> r0
                            to a0
                        .endif
                        .if a2 <> r0
                            from a2
                        .endif
                    .endif
                .elseif a2 = r6
                    .if a0 = a3
                        .if a0 <> r0
                            with a0
                        .endif
                    .else
                        .if a0 <> r0
                            to a0
                        .endif
                        .if a3 <> r0
                            from a3
                        .endif
                    .endif
                .else
                    .assert 0, error, .concat(_CASFX_ERR_STR, "LMULT: at least one source register must be R6")
                .endif
            .endif
        .else
            .if a0 <> r0
            with a0
            .endif
        .endif
    .endif
    mlmult
.endmac

.macro merge a0, a1, a2
    .ifnblank a1
        .ifnblank a2
            .assert a1 = r7 && a2 = r8, error, .concat(_CASFX_ERR_STR, "MERGE: source registers must be r7, r8")
        .else
            .assert 0, error, .concat(_CASFX_ERR_STR, "MERGE: 0, 1, or 3 operands please")
        .endif
    .endif
    .ifnblank a0
        .if a0 <> r0
        with a0
        .endif
    .endif
    mmerge
.endmac

.macro plot a0, a1
    .if .paramcount = 2
        .assert a0 = r1 && a1 = r2, error, .concat(_CASFX_ERR_STR, "PLOT: operands must be r1, r2")
    .else
        .assert .paramcount <> 1, error, .concat(_CASFX_ERR_STR, "PLOT: 0 or 2 operands (r1, r2)")
    .endif
    mplot
.endmac
;.define adc     madc
;.define add     madd
;.define alt1    malt1
;.define alt2    malt2
;.define alt3    malt3
;.define and     mand
;.define asr     masr
;.define bcc     mbcc
;.define bcs     mbcs
;.define beq     mbeq
;.define bge     mbge
;.define bic     mbic
;.define blt     mblt
;.define bmi     mbmi
;.define bne     mbne
;.define bpl     mbpl
;.define bra     mbra
;.define bvc     mbvc
;.define bvs     mbvs
;.define cache   mcache
;.define cmode   mcmode
;.define cmp     mcmp
;.define color   mcolor
;.define dec     mdec
;.define div2    mdiv2
;.define fmult   mfmult
;.define from    mfrom
;.define getb    mgetb
;.define getbh   mgetbh
;.define getbl   mgetbl
;.define getbs   mgetbs
;.define getc    mgetc
;.define hib     mhib
;.define ibt     mibt
;.define inc     minc
;.define iwt     miwt
;.define jmp     mjmp
;.define ldb     mldb
;.define ldw     mldw
;.define lea     mlea
;.define link    mlink
;.define ljmp    mljmp
;.define lm      mlm
;.define lms     mlms
;.define lmult   mlmult
;.define lob     mlob
;.define loop    mloop
;.define lsr     mlsr
;.define merge   mmerge
;.define mult    mmult
;.define nop     mnop
;.define not     mnot
;.define or      mor
;.define plot    mplot
;.define ramb    mramb
;.define rol     mrol
;.define romb    mromb
;.define ror     mror
;.define rpix    mrpix
;.define sbc     msbc
;.define sbk     msbk
;.define sex     msex
;.define sm      msm
;.define sms     msms
;.define stb     mstb
;.define stop    mstop
;.define stw     mstw
;.define sub     msub
;.define swap    mswap
;.define to      mto
;.define umult   mumult
;.define with    mwith
;.define xor     mxor

.endif
