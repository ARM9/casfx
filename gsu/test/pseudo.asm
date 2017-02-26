.include "../casfx.inc"

    .code
main:

    add r0, r1, r0
    adc r0, r0, r1
    adc r1, r0, #1
    sub r1, r1, r1
    sub r1, r1, r0
    sbc r15, r15, r15
    mult r1, r2, r15
    umult r0, r1, #15

    asr r0
    lsr r1
    hib r0, r0
    lob r1, r1
    div2 r0, r1
    rol r1, r0
    ror r1, r2

    fmult r1, r6, r1
    fmult r1, r6
    fmult r2
    fmult r0, r0, r6
    fmult r0, r6
    fmult r0
    fmult r1, r0, r6

    lmult r1
    lmult r0
    lmult r0, r4, r0, r6
    lmult r1, r4, r1, r6
    lmult r1, r4, r2, r6
    lmult r1, r4, r0, r6
    lmult r0, r4, r1, r6

    getb r1
    getbl r0

    merge r0, r7, r8
    merge r0
    merge r1, r7, r8
    merge r1
    plot r1, r2

    moveb r1, (r2)
    moveb r0, (r3)

    jal main
    ret
    pop r15
    pop r0, r1, r15

; vim:ft=snes
