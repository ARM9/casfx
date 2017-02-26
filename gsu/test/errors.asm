    .include "../casfx.inc"
    .code
main:
    fmult r4
    fmult r1, r1
    fmult r1, r1, r1

    lmult r4
    lmult r1, r4
    lmult r1, r4, r1
    lmult r1, r4, r1, r1
    lmult r4, r1, r1, r6

    merge r0, r7
    merge r0, r1, r2
    merge r0, r7, r2
    merge r0, r8, r7

    plot r1
    plot r2
    plot r2, r1
