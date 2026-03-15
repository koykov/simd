#include "textflag.h"

// func memsetSSE2(p []uint64, val uint64)
TEXT ·memsetSSE2(SB), NOSPLIT, $0-32
    MOVQ    p_data+0(FP), DI   // DI = &p[0]
    MOVQ    p_len+8(FP), CX    // CX = len(p)
    MOVQ    val+24(FP), AX     // AX = val

    // Broadcast val to XMM0
    MOVQ    AX, X0
    PUNPCKLQDQ X0, X0         // X0 = [val, val]

    // process short inputs (less than 8)
    CMPQ    CX, $8
    JB      small

    // Prepare XMM registers with the value
    MOVAPS  X0, X1
    MOVAPS  X0, X2
    MOVAPS  X0, X3

    // prepare main loop (8 items per iteration)
    MOVQ    CX, DX
    SHRQ    $3, DX            // DX = len(p) / 8
    JZ      tail_sse2

sse2_loop:
    MOVUPS  X0, (DI)          // write 16 bytes
    MOVUPS  X1, 16(DI)        // write 16 bytes
    MOVUPS  X2, 32(DI)        // write 16 bytes
    MOVUPS  X3, 48(DI)        // write 16 bytes
    ADDQ    $64, DI           // shift pointer
    DECQ    DX                // reduce counter
    JNZ     sse2_loop         // check DX != 0

    // tail processing (0-7 items)
tail_sse2:
    ANDQ    $7, CX            // remains in CX (0-7)
    JZ      done

    // process 4 items
    CMPQ    CX, $4
    JB      lt4
    MOVUPS  X0, (DI)
    MOVUPS  X1, 16(DI)
    ADDQ    $32, DI
    SUBQ    $4, CX

lt4:
    // process 2 items
    CMPQ    CX, $2
    JB      lt2
    MOVQ    X0, (DI)
    MOVQ    X0, 8(DI)
    ADDQ    $16, DI
    SUBQ    $2, CX

lt2:
    // process 1 item
    TESTQ   CX, CX
    JZ      done
    MOVQ    AX, (DI)

done:
    RET

    // process short inputs (0-7 items)
small:
    TESTQ   CX, CX
    JZ      done

    // process 4 items in loop
    MOVQ    CX, DX
    SHRQ    $2, DX
    JZ      tail_small

loop_small:
    MOVQ    AX, (DI)
    MOVQ    AX, 8(DI)
    MOVQ    AX, 16(DI)
    MOVQ    AX, 24(DI)
    ADDQ    $32, DI
    DECQ    DX
    JNZ     loop_small

tail_small:
    ANDQ    $3, CX
    JZ      done

    // process rest of data
    CMPQ    CX, $2
    JB      lt2_small
    MOVQ    AX, (DI)
    MOVQ    AX, 8(DI)
    ADDQ    $16, DI
    SUBQ    $2, CX

lt2_small:
    TESTQ   CX, CX
    JZ      done
    MOVQ    AX, (DI)
    RET

// func memsetAVX2(p []uint64, val uint64)
TEXT ·memsetAVX2(SB), NOSPLIT, $0-32
    MOVQ    p_data+0(FP), DI   // DI = &p[0]
    MOVQ    p_len+8(FP), CX    // CX = len(p)
    MOVQ    val+24(FP), AX     // AX = val

    // check for huge inputs (>16MB)
    CMPQ    CX, $2097152
    JAE     huge_setting

    // check small inputs (<16 items)
    CMPQ    CX, $16
    JB      small

    // Broadcast val to YMM registers
    VZEROUPPER
    MOVQ    AX, X0
    VPINSRQ $1, AX, X0, X0    // X0 = [val, val]
    VPBROADCASTQ X0, Y0       // Y0 = [val, val, val, val]
    VMOVDQA Y0, Y1
    VMOVDQA Y0, Y2
    VMOVDQA Y0, Y3

    // prepare main loop (16 items per iteration)
    MOVQ    CX, DX
    SHRQ    $4, DX            // DX = len(p) / 16
    JZ      tail_avx2

avx2_loop:
    VMOVDQU Y0, (DI)          // write 32 bytes
    VMOVDQU Y1, 32(DI)        // write 32 bytes
    VMOVDQU Y2, 64(DI)        // write 32 bytes
    VMOVDQU Y3, 96(DI)        // write 32 bytes
    ADDQ    $128, DI          // shift pointer
    DECQ    DX                // reduce counter
    JNZ     avx2_loop         // DX != 0

    // tail processing (0-15 items)
tail_avx2:
    ANDQ    $15, CX           // remains in CX (0-15)
    JZ      done_avx2

    // process 8 items
    CMPQ    CX, $8
    JB      lt8_avx2
    VMOVDQU Y0, (DI)
    VMOVDQU Y1, 32(DI)
    ADDQ    $64, DI
    SUBQ    $8, CX

lt8_avx2:
    // process 4 items
    CMPQ    CX, $4
    JB      lt4_avx2
    VMOVDQU Y0, (DI)
    ADDQ    $32, DI
    SUBQ    $4, CX

lt4_avx2:
    // process 2 items
    CMPQ    CX, $2
    JB      lt2_avx2
    VMOVQ   X0, (DI)
    VMOVQ   X0, 8(DI)
    ADDQ    $16, DI
    SUBQ    $2, CX

lt2_avx2:
    // process 1 item
    TESTQ   CX, CX
    JZ      done_avx2
    MOVQ    AX, (DI)

done_avx2:
    VZEROUPPER
    RET

    // huge inputs processing (>16MB)
huge_setting:
    VZEROUPPER
    MOVQ    AX, X0
    VPINSRQ $1, AX, X0, X0    // X0 = [val, val]
    VPBROADCASTQ X0, Y0       // Y0 = [val, val, val, val]
    VMOVDQA Y0, Y1

    // main loop - 256 bytes (32 items) per iteration
    MOVQ    CX, DX
    SHRQ    $5, DX            // DX = len(p) / 32
    JZ      huge_tail

huge_loop:
    PREFETCHNTA 1024(DI)
    VMOVNTDQ Y0, (DI)         // Non-temporal store
    VMOVNTDQ Y1, 32(DI)
    VMOVNTDQ Y0, 64(DI)
    VMOVNTDQ Y1, 96(DI)
    VMOVNTDQ Y0, 128(DI)
    VMOVNTDQ Y1, 160(DI)
    VMOVNTDQ Y0, 192(DI)
    VMOVNTDQ Y1, 224(DI)
    ADDQ    $256, DI          // shift pointer
    DECQ    DX                // reduce counter
    JNZ     huge_loop         // DX != 0

    SFENCE                    // NT op barrier
    ANDQ    $31, CX           // remains in CX (0-31)
    JZ      done

    // process rest of items
huge_tail:
    VMOVDQU Y0, (DI)
    VMOVDQU Y1, 32(DI)
    VMOVDQU Y0, 64(DI)
    VMOVDQU Y1, 96(DI)
    JMP     done

    // process short inputs (0-15 items)
small:
    TESTQ   CX, CX
    JZ      done

    // process loop for 8 items per iteration
    MOVQ    CX, DX
    SHRQ    $3, DX
    JZ      tail_small

loop_small:
    MOVQ    AX, (DI)
    MOVQ    AX, 8(DI)
    MOVQ    AX, 16(DI)
    MOVQ    AX, 24(DI)
    MOVQ    AX, 32(DI)
    MOVQ    AX, 40(DI)
    MOVQ    AX, 48(DI)
    MOVQ    AX, 56(DI)
    ADDQ    $64, DI
    DECQ    DX
    JNZ     loop_small

tail_small:
    ANDQ    $7, CX
    JZ      done

    // process rest of data
    CMPQ    CX, $4
    JB      lt4_small
    MOVQ    AX, (DI)
    MOVQ    AX, 8(DI)
    MOVQ    AX, 16(DI)
    MOVQ    AX, 24(DI)
    ADDQ    $32, DI
    SUBQ    $4, CX

lt4_small:
    CMPQ    CX, $2
    JB      lt2_small
    MOVQ    AX, (DI)
    MOVQ    AX, 8(DI)
    ADDQ    $16, DI
    SUBQ    $2, CX

lt2_small:
    TESTQ   CX, CX
    JZ      done
    MOVQ    AX, (DI)

done:
    RET

// func memsetAVX512(p []uint64, val uint64)
TEXT ·memsetAVX512(SB), NOSPLIT, $0-32
    MOVQ    p_data+0(FP), DI   // DI = &p[0]
    MOVQ    p_len+8(FP), CX    // CX = len(p)
    MOVQ    val+24(FP), AX     // AX = val

    // check huge inputs (>16MB)
    CMPQ    CX, $2097152
    JAE     huge_setting

    // check small inputs (<32 items)
    CMPQ    CX, $32
    JB      small

    // Broadcast val to ZMM registers
    MOVQ    AX, X0
    VPINSRQ $1, AX, X0, X0    // X0 = [val, val]
    VPBROADCASTQ X0, Z0       // Z0 = [val x8]
    VMOVDQA64 Z0, Z1
    VMOVDQA64 Z0, Z2
    VMOVDQA64 Z0, Z3

    // main loop - process 256 bytes (32 items) per iteration
    MOVQ    CX, DX
    SHRQ    $5, DX            // DX = len(p) / 32
    JZ      tail_avx512

avx512_loop:
    VMOVDQU64 Z0, (DI)        // write 64 bytes
    VMOVDQU64 Z1, 64(DI)      // write 64 bytes
    VMOVDQU64 Z2, 128(DI)     // write 64 bytes
    VMOVDQU64 Z3, 192(DI)     // write 64 bytes
    ADDQ    $256, DI          // shift pointer
    DECQ    DX                // reduce counter
    JNZ     avx512_loop       // DX != 0

    // tail processing (0-31 items)
tail_avx512:
    ANDQ    $31, CX           // remains in CX (0-31)
    JZ      done_avx512

    // process 16 items
    CMPQ    CX, $16
    JB      lt16_avx512
    VMOVDQU64 Z0, (DI)
    VMOVDQU64 Z1, 64(DI)
    ADDQ    $128, DI
    SUBQ    $16, CX

lt16_avx512:
    // process 8 items
    CMPQ    CX, $8
    JB      lt8_avx512
    VMOVDQU64 Z0, (DI)
    ADDQ    $64, DI
    SUBQ    $8, CX

lt8_avx512:
    // process 4 items
    CMPQ    CX, $4
    JB      lt4_avx512
    VMOVDQU Y0, (DI)
    ADDQ    $32, DI
    SUBQ    $4, CX

lt4_avx512:
    // process 2 items
    CMPQ    CX, $2
    JB      lt2_avx512
    VMOVQ   X0, (DI)
    VMOVQ   X0, 8(DI)
    ADDQ    $16, DI
    SUBQ    $2, CX

lt2_avx512:
    // process 1 item
    TESTQ   CX, CX
    JZ      done_avx512
    MOVQ    AX, (DI)

done_avx512:
    VZEROUPPER
    RET

    // process huge inputs (>16MB)
huge_setting:
    MOVQ    AX, X0
    VPINSRQ $1, AX, X0, X0    // X0 = [val, val]
    VPBROADCASTQ X0, Z0       // Z0 = [val x8]
    VMOVDQA64 Z0, Z1

    // main loop - process 512 bytes (64 items) per iteration
    MOVQ    CX, DX
    SHRQ    $6, DX            // DX = len(p) / 64
    JZ      huge_tail

huge_loop:
    PREFETCHNTA 2048(DI)
    VMOVNTDQ Z0, (DI)         // Non-temporal store
    VMOVNTDQ Z1, 64(DI)
    VMOVNTDQ Z0, 128(DI)
    VMOVNTDQ Z1, 192(DI)
    VMOVNTDQ Z0, 256(DI)
    VMOVNTDQ Z1, 320(DI)
    VMOVNTDQ Z0, 384(DI)
    VMOVNTDQ Z1, 448(DI)
    ADDQ    $512, DI          // shift pointer
    DECQ    DX                // reduce counter
    JNZ     huge_loop         // DX != 0

    SFENCE                    // NT op barrier
    ANDQ    $63, CX           // remains in CX (0-63)
    JZ      done

    // process tail (0-63 items)
huge_tail:
    CMPQ    CX, $32
    JB      huge_lt32
    VMOVDQU64 Z0, (DI)
    VMOVDQU64 Z1, 64(DI)
    VMOVDQU64 Z0, 128(DI)
    VMOVDQU64 Z1, 192(DI)
    ADDQ    $256, DI
    SUBQ    $32, CX

huge_lt32:
    JMP     tail_avx512

    // process small inputs (0-31 items)
small:
    TESTQ   CX, CX
    JZ      done

    // process 16 items
    MOVQ    CX, DX
    SHRQ    $4, DX
    JZ      tail_small

loop_small:
    MOVQ    AX, (DI)
    MOVQ    AX, 8(DI)
    MOVQ    AX, 16(DI)
    MOVQ    AX, 24(DI)
    MOVQ    AX, 32(DI)
    MOVQ    AX, 40(DI)
    MOVQ    AX, 48(DI)
    MOVQ    AX, 56(DI)
    MOVQ    AX, 64(DI)
    MOVQ    AX, 72(DI)
    MOVQ    AX, 80(DI)
    MOVQ    AX, 88(DI)
    MOVQ    AX, 96(DI)
    MOVQ    AX, 104(DI)
    MOVQ    AX, 112(DI)
    MOVQ    AX, 120(DI)
    ADDQ    $128, DI
    DECQ    DX
    JNZ     loop_small

tail_small:
    ANDQ    $15, CX
    JZ      done

    // process rest of data
    CMPQ    CX, $8
    JB      lt8_small
    MOVQ    AX, (DI)
    MOVQ    AX, 8(DI)
    MOVQ    AX, 16(DI)
    MOVQ    AX, 24(DI)
    MOVQ    AX, 32(DI)
    MOVQ    AX, 40(DI)
    MOVQ    AX, 48(DI)
    MOVQ    AX, 56(DI)
    ADDQ    $64, DI
    SUBQ    $8, CX

lt8_small:
    CMPQ    CX, $4
    JB      lt4_small
    MOVQ    AX, (DI)
    MOVQ    AX, 8(DI)
    MOVQ    AX, 16(DI)
    MOVQ    AX, 24(DI)
    ADDQ    $32, DI
    SUBQ    $4, CX

lt4_small:
    CMPQ    CX, $2
    JB      lt2_small
    MOVQ    AX, (DI)
    MOVQ    AX, 8(DI)
    ADDQ    $16, DI
    SUBQ    $2, CX

lt2_small:
    TESTQ   CX, CX
    JZ      done
    MOVQ    AX, (DI)

done:
    VZEROUPPER
    RET
