.include "../casfx.inc"

    .code
main:
    ;add r0, r1, r0
    from r1
    add r0
    ;adc r0, r0, r1
    adc r1
    ;adc r1, r0, #1
    to r1
    adc #1
    ;sub r1, r1, r1
    with r1
    sub r1
    ;sub r1, r1, r0
    with r1
    sub r0
    ;sbc r15, r15, r15
    with r15
    sbc r15
    ;mult r1, r2, r15
    to r1
    from r2
    mult r15
    ;umult r0, r1, #15
    from r1
    umult #15

    ;asr r0
    asr
    ;lsr r1
    with r1
    lsr
    ;hib r0, r0
    hib
    ;lob r1, r1
    with r1
    lob
    ;div2 r0, r1
    from r1
    div2
    ;rol r1, r0
    to r1
    rol
    ;ror r1, r2
    to r1
    from r2
    ror

    ;fmult r1, r6, r1
    with r1
    fmult
    ;fmult r1, r6
    with r1
    fmult
    ;fmult r2
    with r2
    fmult
    ;fmult r0, r0, r6
    fmult
    ;fmult r0, r6
    fmult
    ;fmult r0
    fmult
    ;fmult r1, r0, r6
    to r1
    fmult

    ;lmult r1
    with r1
    lmult
    ;lmult r0
    lmult
    ;lmult r0, r4, r0, r6
    lmult
    ;lmult r1, r4, r1, r6
    with r1
    lmult
    ;lmult r1, r4, r2, r6
    to r1
    from r2
    lmult
    ;lmult r1, r4, r0, r6
    to r1
    lmult
    ;lmult r0, r4, r1, r6
    from r1
    lmult

    ;getb r1
    with r1
    getb
    ;getbl r0
    getbl

    ;merge r0, r7, r8
    merge
    ;merge r0
    merge
    ;merge r1, r7, r8
    with r1
    merge
    ;merge r1
    with r1
    merge
    ;plot r1, r2
    plot

    ;moveb r1, (r2)
    with r1
    ldb (r2)

    ;moveb r0, (r3)
    ldb (r3)

    ;jal main
    link #4
    iwt r15, #main
    ;ret
    jmp r11
    ;pop r15
    inc r10
    inc r10
    with r15
    ldw (r10)
    ;pop r0, r1, r15
    inc r10
    inc r10
    ldw (r10)
    inc r10
    inc r10
    with r1
    ldw (r10)
    inc r10
    inc r10
    with r15
    ldw (r10)

; vim:ft=snes
