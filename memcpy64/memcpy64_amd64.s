#include "textflag.h"

// func memcpySSE2(dst, src []uint64)
TEXT ·memcpySSE2(SB), NOSPLIT, $0-48
    MOVQ dst_base+0(FP), DI
    MOVQ src_base+24(FP), SI
    MOVQ src_len+32(FP), CX

    TESTQ CX, CX
    JZ   done

    SHLQ $3, CX

    MOVQ CX, R8
    MOVQ CX, AX
    SHRQ $6, AX
    ANDQ $63, R8

    TESTQ AX, AX
    JZ   process_16


loop_unrolled:
    MOVOU (SI), X0
    MOVOU 16(SI), X1
    MOVOU 32(SI), X2
    MOVOU 48(SI), X3

    MOVOU X0, (DI)
    MOVOU X1, 16(DI)
    MOVOU X2, 32(DI)
    MOVOU X3, 48(DI)

    ADDQ $64, SI
    ADDQ $64, DI
    DECQ AX
    JNZ  loop_unrolled

process_16:
    MOVQ R8, CX
    MOVQ CX, R8
    SHRQ $4, CX
    ANDQ $15, R8

    TESTQ CX, CX
    JZ   tail

loop_16:
    MOVOU (SI), X0
    MOVOU X0, (DI)
    ADDQ $16, SI
    ADDQ $16, DI
    DECQ CX
    JNZ  loop_16

tail:
    TESTQ R8, R8
    JZ   done

    CMPQ R8, $8
    JL   tail_less_8

    MOVQ (SI), DX
    MOVQ DX, (DI)
    ADDQ $8, SI
    ADDQ $8, DI
    SUBQ $8, R8
    JMP  tail

tail_less_8:
    CMPQ R8, $4
    JL   tail_less_4

    MOVL (SI), DX
    MOVL DX, (DI)
    ADDQ $4, SI
    ADDQ $4, DI
    SUBQ $4, R8
    JMP  tail_less_8

tail_less_4:
    CMPQ R8, $2
    JL   tail_less_2

    MOVW (SI), DX
    MOVW DX, (DI)
    ADDQ $2, SI
    ADDQ $2, DI
    SUBQ $2, R8

tail_less_2:
    CMPQ R8, $1
    JL   done

    MOVB (SI), DX
    MOVB DX, (DI)

done:
    RET

// func memcpyAVX2(dst, src []uint64)
TEXT ·memcpyAVX2(SB), NOSPLIT, $0-48
    MOVQ dst_base+0(FP), DI
    MOVQ src_base+24(FP), SI
    MOVQ src_len+32(FP), CX

    TESTQ CX, CX
    JZ   done

    SHLQ $3, CX               

    MOVQ CX, R8               
    MOVQ CX, AX
    SHRQ $7, AX               
    ANDQ $127, R8             

    TESTQ AX, AX
    JZ   process_32


loop_unrolled_avx2:
    VMOVDQU (SI), Y0
    VMOVDQU 32(SI), Y1
    VMOVDQU 64(SI), Y2
    VMOVDQU 96(SI), Y3


    VMOVDQU Y0, (DI)
    VMOVDQU Y1, 32(DI)
    VMOVDQU Y2, 64(DI)
    VMOVDQU Y3, 96(DI)

    ADDQ $128, SI
    ADDQ $128, DI
    DECQ AX
    JNZ  loop_unrolled_avx2

process_32:
    MOVQ R8, CX
    MOVQ CX, R8
    SHRQ $5, CX
    ANDQ $31, R8

    TESTQ CX, CX
    JZ   process_16

loop_32:
    VMOVDQU (SI), Y0
    VMOVDQU Y0, (DI)
    ADDQ $32, SI
    ADDQ $32, DI
    DECQ CX
    JNZ  loop_32

process_16:
    CMPQ R8, $16
    JL   process_less_16

    VMOVDQU (SI), X0
    VMOVDQU X0, (DI)
    ADDQ $16, SI
    ADDQ $16, DI
    SUBQ $16, R8

process_less_16:
    TESTQ R8, R8
    JZ   done

    CMPQ R8, $8
    JL   tail_less_8

    MOVQ (SI), DX
    MOVQ DX, (DI)
    ADDQ $8, SI
    ADDQ $8, DI
    SUBQ $8, R8
    JMP  process_less_16

tail_less_8:
    CMPQ R8, $4
    JL   tail_less_4

    MOVL (SI), DX
    MOVL DX, (DI)
    ADDQ $4, SI
    ADDQ $4, DI
    SUBQ $4, R8
    JMP  tail_less_8

tail_less_4:
    CMPQ R8, $2
    JL   tail_less_2

    MOVW (SI), DX
    MOVW DX, (DI)
    ADDQ $2, SI
    ADDQ $2, DI
    SUBQ $2, R8

tail_less_2:
    CMPQ R8, $1
    JL   done

    MOVB (SI), DX
    MOVB DX, (DI)

done:
    VZEROUPPER
    RET
