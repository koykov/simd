#include "textflag.h"

// func memclrSSE2(p []uint64)
TEXT ·memclrSSE2(SB), NOSPLIT, $0-24
    MOVQ    p_data+0(FP), DI   // point to slice start (DI = &p[0])
    MOVQ    p_len+8(FP), CX    // slice len (CX = len(p))

    // process short inputs (less than 8)
    CMPQ    CX, $8
    JB      small

    // clear SSE2 regs
    XORPS   X0, X0            // XMM0
    XORPS   X1, X1            // XMM1
    XORPS   X2, X2            // XMM2
    XORPS   X3, X3            // XMM3

    // prepare main loop (8 items per iteration)
    MOVQ    CX, DX
    SHRQ    $3, DX            // DX = DX >> 8
    JZ      tail_sse2

sse2_loop:
    MOVUPS  X0, (DI)          // write zero bits to 16 bytes
    MOVUPS  X1, 16(DI)        // write zero bits to 16 bytes
    MOVUPS  X2, 32(DI)        // write zero bits to 16 bytes
    MOVUPS  X3, 48(DI)        // write zero bits to 16 bytes
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
    MOVQ    $0, (DI)

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
    MOVQ    $0, (DI)
    MOVQ    $0, 8(DI)
    MOVQ    $0, 16(DI)
    MOVQ    $0, 24(DI)
    ADDQ    $32, DI
    DECQ    DX
    JNZ     loop_small

tail_small:
    ANDQ    $3, CX
    JZ      done

    // process rest of data
    CMPQ    CX, $2
    JB      lt2_small
    MOVQ    $0, (DI)
    MOVQ    $0, 8(DI)
    ADDQ    $16, DI
    SUBQ    $2, CX

lt2_small:
    TESTQ   CX, CX
    JZ      done
    MOVQ    $0, (DI)
    RET

// func memclrAVX2(p []uint64)
TEXT ·memclrAVX2(SB), NOSPLIT, $0-24
    MOVQ    p_data+0(FP), DI   // point to slice start (DI = &p[0])
    MOVQ    p_len+8(FP), CX    // slice len (CX = len(p))

    // check for huge inputs (>16MB)
    CMPQ    CX, $2097152
    JAE     huge_clearing

    // check small inputs (<16 items)
    CMPQ    CX, $16
    JB      small

    // prepare AVX2 regs
    VZEROUPPER
    VPXOR   Y0, Y0, Y0        // YMM0
    VPXOR   Y1, Y1, Y1        // YMM1
    VPXOR   Y2, Y2, Y2        // YMM2
    VPXOR   Y3, Y3, Y3        // YMM3

    // prepare main loop (16 items per iteration)
    MOVQ    CX, DX
    SHRQ    $4, DX            // DX = DS >> 16
    JZ      tail_avx2

avx2_loop:
    VMOVDQU Y0, (DI)          // write zero bits to 32 bytes
    VMOVDQU Y1, 32(DI)        // ...
    VMOVDQU Y2, 64(DI)        // ...
    VMOVDQU Y3, 96(DI)        // ...
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
    MOVQ    $0, (DI)

done_avx2:
    VZEROUPPER
    RET

    // huge inputs processing (>16MB)
huge_clearing:
    VZEROUPPER
    VPXOR   Y0, Y0, Y0        // clear YMM0
    VPXOR   Y1, Y1, Y1        // clear YMM1

    // main loop - 256 bytes (32 items) per iteration
    MOVQ    CX, DX
    SHRQ    $5, DX            // DX = DX >> 5
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
    MOVQ    $0, (DI)
    MOVQ    $0, 8(DI)
    MOVQ    $0, 16(DI)
    MOVQ    $0, 24(DI)
    MOVQ    $0, 32(DI)
    MOVQ    $0, 40(DI)
    MOVQ    $0, 48(DI)
    MOVQ    $0, 56(DI)
    ADDQ    $64, DI
    DECQ    DX
    JNZ     loop_small

tail_small:
    ANDQ    $7, CX
    JZ      done

    // process rest of data
    CMPQ    CX, $4
    JB      lt4_small
    MOVQ    $0, (DI)
    MOVQ    $0, 8(DI)
    MOVQ    $0, 16(DI)
    MOVQ    $0, 24(DI)
    ADDQ    $32, DI
    SUBQ    $4, CX

lt4_small:
    CMPQ    CX, $2
    JB      lt2_small
    MOVQ    $0, (DI)
    MOVQ    $0, 8(DI)
    ADDQ    $16, DI
    SUBQ    $2, CX

lt2_small:
    TESTQ   CX, CX
    JZ      done
    MOVQ    $0, (DI)

done:
    RET

// func memclrAVX512(p []uint64)
TEXT ·memclrAVX512(SB), NOSPLIT, $0-24
    MOVQ    p_data+0(FP), DI   // point to slice start (DI = &p[0])
    MOVQ    p_len+8(FP), CX    // slice len (CX = len(p))

    // check huge inputs (>16MB)
    CMPQ    CX, $2097152
    JAE     huge_clearing

    // check small inputs (<32 items)
    CMPQ    CX, $32
    JB      small

    // prepare AVX-512 regs
    VPXORQ  Z0, Z0, Z0        // ZMM0
    VPXORQ  Z1, Z1, Z1        // ZMM1
    VPXORQ  Z2, Z2, Z2        // ZMM2
    VPXORQ  Z3, Z3, Z3        // ZMM3

    // main loop - process 256 bytes (32 items) per iteration
    MOVQ    CX, DX
    SHRQ    $5, DX            // DX = DX >> 5
    JZ      tail_avx512

avx512_loop:
    VMOVDQU64 Z0, (DI)        // write zero bits to 64 bytes
    VMOVDQU64 Z1, 64(DI)
    VMOVDQU64 Z2, 128(DI)
    VMOVDQU64 Z3, 192(DI)
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
    MOVQ    $0, (DI)

done_avx512:
    VZEROUPPER
    RET

    // process huge inputs (>16MB)
huge_clearing:
    VPXORQ  Z0, Z0, Z0        // ZMM0
    VPXORQ  Z1, Z1, Z1        // ZMM1

    // main loop - process 512 bytes (64 items) per iteration
    MOVQ    CX, DX
    SHRQ    $6, DX            // DX = DX >> 6
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
    MOVQ    $0, (DI)
    MOVQ    $0, 8(DI)
    MOVQ    $0, 16(DI)
    MOVQ    $0, 24(DI)
    MOVQ    $0, 32(DI)
    MOVQ    $0, 40(DI)
    MOVQ    $0, 48(DI)
    MOVQ    $0, 56(DI)
    MOVQ    $0, 64(DI)
    MOVQ    $0, 72(DI)
    MOVQ    $0, 80(DI)
    MOVQ    $0, 88(DI)
    MOVQ    $0, 96(DI)
    MOVQ    $0, 104(DI)
    MOVQ    $0, 112(DI)
    MOVQ    $0, 120(DI)
    ADDQ    $128, DI
    DECQ    DX
    JNZ     loop_small

tail_small:
    ANDQ    $15, CX
    JZ      done

    // process rest of data
    CMPQ    CX, $8
    JB      lt8_small
    MOVQ    $0, (DI)
    MOVQ    $0, 8(DI)
    MOVQ    $0, 16(DI)
    MOVQ    $0, 24(DI)
    MOVQ    $0, 32(DI)
    MOVQ    $0, 40(DI)
    MOVQ    $0, 48(DI)
    MOVQ    $0, 56(DI)
    ADDQ    $64, DI
    SUBQ    $8, CX

lt8_small:
    CMPQ    CX, $4
    JB      lt4_small
    MOVQ    $0, (DI)
    MOVQ    $0, 8(DI)
    MOVQ    $0, 16(DI)
    MOVQ    $0, 24(DI)
    ADDQ    $32, DI
    SUBQ    $4, CX

lt4_small:
    CMPQ    CX, $2
    JB      lt2_small
    MOVQ    $0, (DI)
    MOVQ    $0, 8(DI)
    ADDQ    $16, DI
    SUBQ    $2, CX

lt2_small:
    TESTQ   CX, CX
    JZ      done
    MOVQ    $0, (DI)

done:
    VZEROUPPER
    RET
