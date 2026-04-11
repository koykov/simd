#include "textflag.h"

// func memequalSSE2(a []uint64, b []uint64) bool
TEXT ·memequalSSE2(SB), NOSPLIT, $0-48
    MOVQ a_len+8(FP), CX
    MOVQ a_data+0(FP), SI
    MOVQ b_data+24(FP), DI

    TESTQ CX, CX
    JZ     eq

    MOVQ CX, R8
    SHLQ $3, R8

    MOVQ R8, R9
    SHRQ $4, R9
    JZ    tail

    XORQ R10, R10

loop:
    MOVOU (SI)(R10*1), X0
    MOVOU (DI)(R10*1), X1
    PCMPEQB X0, X1
    PMOVMSKB X1, R11
    CMPL R11, $0xFFFF
    JNE  neq

    ADDQ $16, R10
    DECQ R9
    JNZ  loop

tail:
    MOVQ R8, R9
    ANDQ $15, R9
    JZ   eq

    MOVQ R8, R11
    SUBQ R9, R11
    MOVOU (SI)(R11*1), X0
    MOVOU (DI)(R11*1), X1

    PCMPEQB X0, X1
    PMOVMSKB X1, R12

    MOVQ $1, R13
    MOVQ R9, CX
    SHLQ CX, R13
    SUBQ $1, R13

    ANDQ R13, R12
    CMPQ R12, R13
    JNE  neq

eq:
    MOVB $1, ret+48(FP)
    RET

neq:
    MOVB $0, ret+48(FP)
    RET

// func memequalAVX2(a []uint64, b []uint64) bool
TEXT ·memequalAVX2(SB), NOSPLIT, $0-48
    MOVQ a_len+8(FP), CX
    MOVQ a_data+0(FP), SI
    MOVQ b_data+24(FP), DI

    TESTQ CX, CX
    JZ     eq

    MOVQ CX, R8
    SHLQ $3, R8

    MOVQ R8, R9
    SHRQ $5, R9
    XORQ R10, R10

    CMPQ R9, $0
    JE    handle_remainder

loop32:
    VMOVDQU (SI)(R10*1), Y0
    VMOVDQU (DI)(R10*1), Y1
    VPCMPEQB Y0, Y1, Y2
    VPMOVMSKB Y2, R11
    CMPL R11, $0xFFFFFFFF
    JNE  neq

    ADDQ $32, R10
    DECQ R9
    JNZ  loop32

handle_remainder:
    MOVQ R8, R9
    SUBQ R10, R9

    XORQ R11, R11

remainder_loop:
    CMPQ R11, R9
    JAE  eq

    MOVB (SI)(R10*1), R12
    MOVB (DI)(R10*1), R13
    CMPB R12, R13
    JNE  neq

    INCQ R10
    INCQ R11
    JMP  remainder_loop

eq:
    MOVB $1, ret+48(FP)
    VZEROUPPER
    RET

neq:
    MOVB $0, ret+48(FP)
    VZEROUPPER
    RET

// func memequalAVX512(a []uint64, b []uint64) bool
TEXT ·memequalAVX512(SB), NOSPLIT, $0-48
    MOVQ a_len+8(FP), CX
    MOVQ a_data+0(FP), SI
    MOVQ b_data+24(FP), DI

    TESTQ CX, CX
    JZ     eq

    MOVQ CX, BX
    SHLQ $3, BX

    CMPQ BX, $64
    JB    fallback

    PCALIGN $32
loop64:
    CMPQ BX, $64
    JB    fallback

    VMOVDQU (SI), Y0
    VMOVDQU (DI), Y1
    VMOVDQU 32(SI), Y2
    VMOVDQU 32(DI), Y3

    // Сравниваем
    VPCMPEQB Y1, Y0, Y4
    VPCMPEQB Y3, Y2, Y5
    VPAND Y4, Y5, Y6

    VPMOVMSKB Y6, DX
    CMPL DX, $0xFFFFFFFF
    JNE  not_equal

    ADDQ $64, SI
    ADDQ $64, DI
    SUBQ $64, BX
    JMP  loop64

fallback:
    CMPQ BX, $32
    JB   sse2

    VMOVDQU (SI), Y0
    VMOVDQU (DI), Y1
    VPCMPEQB Y1, Y0, Y2
    VPMOVMSKB Y2, DX
    CMPL DX, $0xFFFFFFFF
    JNE  not_equal

    ADDQ $32, SI
    ADDQ $32, DI
    SUBQ $32, BX
    JMP  fallback

sse2:
    CMPQ BX, $16
    JB   bytes

    MOVOU (SI), X0
    MOVOU (DI), X1
    PCMPEQB X1, X0
    PMOVMSKB X0, DX
    CMPL DX, $0xFFFF
    JNE  not_equal

    ADDQ $16, SI
    ADDQ $16, DI
    SUBQ $16, BX
    JMP  sse2

bytes:
    CMPQ BX, $0
    JE   eq

    MOVB (SI), R8
    MOVB (DI), R9
    CMPB R8, R9
    JNE  not_equal

    INCQ SI
    INCQ DI
    DECQ BX
    JMP  bytes

eq:
    MOVB $1, ret+48(FP)
    VZEROUPPER
    RET

not_equal:
    MOVB $0, ret+48(FP)
    VZEROUPPER
    RET
