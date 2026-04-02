#include "textflag.h"

// func encode32AVX2(data []byte, key []byte)
// key must be exactly 32 bytes long
TEXT ·encode32AVX2(SB), NOSPLIT, $0-48
        MOVQ    data_base+0(FP), AX
        MOVQ    data_len+8(FP), CX
        MOVQ    key_base+24(FP), DX
        VMOVDQU (DX), Y0

main_loop:
        CMPQ    CX, $0x40
        JL      tail_start
        VPXOR   (AX), Y0, Y1
        VMOVDQU Y1, (AX)
        VPXOR   32(AX), Y0, Y1
        VMOVDQU Y1, 32(AX)
        ADDQ    $0x40, AX
        SUBQ    $0x40, CX
        JMP     main_loop

tail_start:
        XORQ BX, BX

tail_loop:
        CMPQ CX, $0x00
        JE   done
        MOVB (DX)(BX*1), SI
        XORB (AX), SI
        MOVB SI, (AX)
        INCQ AX
        DECQ CX
        INCQ BX
        CMPQ BX, $0x20
        JE   main_reset_index
        JMP  tail_loop

main_reset_index:
        SUBQ $0x20, BX
        JMP  tail_loop

done:
        RET
