#include "textflag.h"

// func encodeAVX2([]byte, []byte)
TEXT ·encodeAVX2(SB), NOSPLIT, $0-48
        MOVQ    src_base+0(FP), AX
        MOVQ    src_len+8(FP), CX
        MOVQ    key_base+24(FP), DX
        MOVQ    key_len+32(FP), BX

        CMPQ    BX, $0
        JNE     init_key
        RET

init_key:
        CMPQ    BX, $32
        JE      load_full_key
        JB      expand_short_key

        VMOVDQU (DX), Y0
        JMP     block_loop

load_full_key:
        VMOVDQU (DX), Y0
        JMP     block_loop

expand_short_key:
        VPXOR   Y0, Y0, Y0

        CMPQ    BX, $16
        JAE     copy_16_bytes
        CMPQ    BX, $8
        JAE     copy_8_bytes
        CMPQ    BX, $4
        JAE     copy_4_bytes
        CMPQ    BX, $2
        JAE     copy_2_bytes

        MOVB    (DX), R8
        VPINSRB $0, R8, Y0, Y0
        JMP     expand_loop

copy_2_bytes:
        MOVW    (DX), R8
        VPINSRW $0, R8, Y0, Y0
        JMP     expand_loop

copy_4_bytes:
        MOVL    (DX), R8
        VPINSRD $0, R8, Y0, Y0
        JMP     expand_loop

copy_8_bytes:
        MOVQ    (DX), R8
        VPINSRQ $0, R8, Y0, Y0
        JMP     expand_loop

copy_16_bytes:
        VMOVDQU (DX), X0
        VINSERTI128 $1, X0, Y0, Y0

expand_loop:
        MOVQ    BX, R8
        MOVQ    BX, R9

expand_copy:
        CMPQ    R8, $32
        JAE     block_loop

        MOVQ    R9, R10
        SUBQ    R8, R10
        CMPQ    R10, BX
        JLE     copy_remaining
        MOVQ    BX, R10

copy_remaining:
        CMPQ    R10, $16
        JAE     copy_16_remain
        CMPQ    R10, $8
        JAE     copy_8_remain
        CMPQ    R10, $4
        JAE     copy_4_remain
        CMPQ    R10, $2
        JAE     copy_2_remain

        MOVB    (DX), R11
        VPINSRB $0, R11, Y0, Y0
        JMP     advance_pointer

copy_2_remain:
        MOVW    (DX), R11
        VPINSRW $0, R11, Y0, Y0
        JMP     advance_pointer

copy_4_remain:
        MOVL    (DX), R11
        VPINSRD $0, R11, Y0, Y0
        JMP     advance_pointer

copy_8_remain:
        MOVQ    (DX), R11
        VPINSRQ $0, R11, Y0, Y0
        JMP     advance_pointer

copy_16_remain:
        VMOVDQU (DX), X0
        VINSERTI128 $1, X0, Y0, Y0

advance_pointer:
        ADDQ    R10, R8
        JMP     expand_copy

block_loop:
        CMPQ    CX, $64
        JL      block_loop_end

        VPXOR   (AX), Y0, Y1
        VMOVDQU Y1, (AX)
        VPXOR   32(AX), Y0, Y1
        VMOVDQU Y1, 32(AX)

        ADDQ    $64, AX
        SUBQ    $64, CX
        JMP     block_loop

block_loop_end:
        TESTQ   CX, CX
        JZ      done

        XORQ    R8, R8
        XORQ    R9, R9

tail_loop:
        CMPQ    R8, CX
        JGE     done

        CMPQ    R9, $0
        JNE     tail_xor

        VMOVDQA Y0, Y1

tail_xor:
        CMPQ    CX, R8
        SUBQ    R8, R11
        CMPQ    R11, $32
        JL      tail_byte_loop

        VPXOR   (AX)(R8*1), Y1, Y2
        VMOVDQU Y2, (AX)(R8*1)
        ADDQ    $32, R8
        XORQ    R9, R9
        JMP     tail_loop

tail_byte_loop:
        MOVB    (AX)(R8*1), R10
        VEXTRACTI128 $0, Y1, X2
        MOVQ    R9, R11
        ANDQ    $15, R11
        CMPQ    R11, $16
        JGE     use_upper_half
        PEXTRB  R11, X2, R12
        JMP     do_xor

use_upper_half:
        VEXTRACTI128 $1, Y1, X2
        SUBQ    $16, R11
        PEXTRB  R11, X2, R12

do_xor:
        XORB    R12, R10
        MOVB    R10, (AX)(R8*1)
        INCQ    R8
        INCQ    R9
        CMPQ    R9, $32
        JNE     tail_byte_loop_continue
        XORQ    R9, R9

tail_byte_loop_continue:
        JMP     tail_loop

done:
        RET
