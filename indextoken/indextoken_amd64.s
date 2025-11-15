#include "textflag.h"

// func indextokenSSE2(b []byte) int
TEXT ·indextokenSSE2(SB), NOSPLIT, $0-32
    MOVQ b_base+0(FP), SI
    MOVQ b_len+8(FP), CX
    XORQ AX, AX

    TESTQ CX, CX
    JZ    not_found

    MOVOU ·mask0(SB), X0
    MOVOU ·mask1(SB), X1

loop16:
    CMPQ CX, $16
    JB   tail

    MOVOU (SI), X2

    MOVOU X2, X3
    PCMPEQB X0, X3
    PMOVMSKB X3, DX
    TESTL DX, DX
    JNZ   found_in_chunk

    MOVOU X2, X3
    PCMPEQB X1, X3
    PMOVMSKB X3, DX
    TESTL DX, DX
    JNZ   found_in_chunk

    ADDQ $16, SI
    ADDQ $16, AX
    SUBQ $16, CX
    JMP  loop16

tail:
    TESTQ CX, CX
    JZ    not_found

    MOVQ SI, DI
    MOVQ CX, DX

tail_loop:
    MOVB (DI), BL
    CMPB BL, $0x2E
    JE   found_tail
    CMPB BL, $0x5B
    JE   found_tail
    CMPB BL, $0x5D
    JE   found_tail
    CMPB BL, $0x40
    JE   found_tail

    INCQ DI
    DECQ DX
    JNZ  tail_loop

    JMP  not_found

found_tail:
    SUBQ SI, DI
    ADDQ DI, AX
    JMP  done

found_in_chunk:
    BSFW DX, DX
    ADDQ DX, AX
    JMP  done

not_found:
    MOVQ $-1, AX

done:
    MOVQ AX, ret+24(FP)
    RET

DATA ·mask0+0(SB)/8, $0x5B2E5B2E5B2E5B2E
DATA ·mask0+8(SB)/8, $0x5B2E5B2E5B2E5B2E
DATA ·mask1+0(SB)/8, $0x40405D40405D4040
DATA ·mask1+8(SB)/8, $0x40405D40405D4040
GLOBL ·mask0(SB), (NOPTR+RODATA), $16
GLOBL ·mask1(SB), (NOPTR+RODATA), $16
