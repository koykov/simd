#include "textflag.h"

// SSE2 version
TEXT ·countSSE2(SB), NOSPLIT, $0-32
    MOVQ data+0(FP), SI   // point to slice start (SI = &data[0])
    MOVQ len+8(FP), CX    // slice len (CX = len(data))
    XORQ AX, AX           // reset acc (AX = 0)

    // check if slice len is less than 2
    CMPQ CX, $2
    JL   remainder        // go to remainder label

    // prepare SSE2 regs
    XORPS X0, X0          // clean reg X0 (acc)
    MOVQ $0x5555555555555555, DX
    MOVQ DX, X1           // apply mask 0x5555555555555555 to X1
    MOVQ $0x3333333333333333, DX
    MOVQ DX, X2           // apply mask 0x3333333333333333 to X2
    MOVQ $0x0F0F0F0F0F0F0F0F, DX
    MOVQ DX, X3           // apply mask 0x0F0F0F0F0F0F0F0F to X3

sse_loop:
    // load 2 numbers (128 бит) to X4
    MOVUPS (SI), X4       // apply MOVUPS to load unaligned data

    ANDPS X1, X4          // X4 = X4 & 0x5555555555555555
    PSRLQ $1, X4          // X4 = X4 >> 1
    ANDPS X1, X4          // X4 = (X4 >> 1) & 0x5555555555555555
    PADDQ X4, X0          // X0 += X4

    ANDPS X2, X4          // X4 = X4 & 0x3333333333333333
    PSRLQ $2, X4          // X4 = X4 >> 2
    ANDPS X2, X4          // X4 = (X4 >> 2) & 0x3333333333333333
    PADDQ X4, X0          // X0 += X4

    ANDPS X3, X4          // X4 = X4 & 0x0F0F0F0F0F0F0F0F
    PSRLQ $4, X4          // X4 = X4 >> 4
    ANDPS X3, X4          // X4 = (X4 >> 4) & 0x0F0F0F0F0F0F0F0F
    PADDQ X4, X0          // X0 += X4

    // switch to next block
    ADDQ $16, SI          // SI += 16 (2 64-bit numbers)
    SUBQ $2, CX           // CX -= 2
    CMPQ CX, $2
    JGE  sse_loop         // repeat till CX >= 2

    // sum X0 to AX
    MOVQ X0, AX           // extract low 64 bits from X0 to AX
    PSHUFD $0b11101110, X0, X1  // move high 64 bits to low
    MOVQ X1, DX           // move high 64 bits to DX
    ADDQ DX, AX           // AX+DX

remainder:
    // process remain number (less than 2)
    CMPQ CX, $0
    JE   done

    // start loop to process remain numbers using POPCNT
    XORQ DX, DX
remainder_loop:
    POPCNTQ (SI), DX
    ADDQ DX, AX
    ADDQ $8, SI
    LOOP remainder_loop

done:
    MOVQ AX, ret+24(FP)
    RET

// AVX-2 version
TEXT ·countAVX2(SB), NOSPLIT, $0-32
    MOVQ data+0(FP), SI   // point to slice start (SI = &data[0])
    MOVQ len+8(FP), CX    // slice len (CX = len(data))
    XORQ AX, AX           // reset acc (AX = 0)

    // check if slice len is less than 4
    CMPQ CX, $4
    JL   remainder        // go to remainder label

    // prepare AVX-2 regs
    VPXOR Y0, Y0, Y0     // clean reg Y0 (acc)
    MOVQ $0x5555555555555555, DX
    VPBROADCASTQ DX, Y1  // apply mask 0x5555555555555555 to Y1
    MOVQ $0x3333333333333333, DX
    VPBROADCASTQ DX, Y2  // apply mask 0x3333333333333333 to Y2
    MOVQ $0x0F0F0F0F0F0F0F0F, DX
    VPBROADCASTQ DX, Y3  // apply mask 0x0F0F0F0F0F0F0F0F to Y3

avx2_loop:
    // load 4 numbers (256 бит) to Y4
    VMOVDQU (SI), Y4

    VPAND Y4, Y1, Y5     // Y5 = Y4 & 0x5555555555555555
    VPSRLQ $1, Y4, Y6    // Y6 = Y4 >> 1
    VPAND Y6, Y1, Y6     // Y6 = (Y4 >> 1) & 0x5555555555555555
    VPADDQ Y5, Y6, Y4    // Y4 = Y5 + Y6

    VPAND Y4, Y2, Y5     // Y5 = Y4 & 0x3333333333333333
    VPSRLQ $2, Y4, Y6    // Y6 = Y4 >> 2
    VPAND Y6, Y2, Y6     // Y6 = (Y4 >> 2) & 0x3333333333333333
    VPADDQ Y5, Y6, Y4    // Y4 = Y5 + Y6

    VPAND Y4, Y3, Y5     // Y5 = Y4 & 0x0F0F0F0F0F0F0F0F
    VPSRLQ $4, Y4, Y6    // Y6 = Y4 >> 4
    VPAND Y6, Y3, Y6     // Y6 = (Y4 >> 4) & 0x0F0F0F0F0F0F0F0F
    VPADDQ Y5, Y6, Y4    // Y4 = Y5 + Y6

    // sum result to Y0
    VPADDQ Y4, Y0, Y0    // Y0 += Y4

    // switch to next block
    ADDQ $32, SI         // SI += 32 (4 64-bit numbers)
    SUBQ $4, CX          // CX -= 4
    CMPQ CX, $4
    JGE  avx2_loop       // repeat till CX >= 4

    // sum Y0 to AX
    VEXTRACTI128 $1, Y0, X1  // extract high 128 bits from Y0 to X1
    VPADDQ X0, X1, X0        // X0+X1
    VPSHUFD $0b11101110, X0, X1  // move high 64 bits to low
    VPADDQ X0, X1, X0        // X0+X1
    VMOVQ X0, AX             // move result to AX

remainder:
    // process remain number (less than 4)
    CMPQ CX, $0
    JE   done

    // start loop to process remain numbers using POPCNT
    XORQ DX, DX
remainder_loop:
    POPCNTQ (SI), DX
    ADDQ DX, AX
    ADDQ $8, SI
    LOOP remainder_loop

done:
    MOVQ AX, ret+24(FP)
    RET

// AVX-512 version
TEXT ·countAVX512(SB), NOSPLIT, $0-32
    MOVQ data+0(FP), SI   // point to slice start (SI = &data[0])
    MOVQ len+8(FP), CX    // slice len (CX = len(data))
    XORQ AX, AX           // reset acc (AX = 0)

    // check if slice len is less than 8
    CMPQ CX, $8
    JL   remainder        // go to remainder label

    // prepare AVX-512 regs
    VPXORQ Z0, Z0, Z0     // clean reg Z0 (acc)

avx512_loop:
    // load 8 numbers (512 бит) to Z1
    VMOVDQU64 (SI), Z1

    // count bits using VPOPCNTQ
    VPOPCNTQ Z1, Z1       // Z1 = nmber of bits in each part of Z1

    // sum to Z0
    VPADDQ Z1, Z0, Z0     // Z0 += Z1

    // switch to next block
    ADDQ $64, SI          // SI += 64 (8 64-bit numbers)
    SUBQ $8, CX           // CX -= 8
    CMPQ CX, $8
    JGE  avx512_loop      // repeat till CX >= 8

    // sum Z0 to AX
    VEXTRACTI64X4 $1, Z0, Y1  // extract high 256 bits from Z0 to Y1
    VPADDQ Y0, Y1, Y0         // Y0 + Y1
    VEXTRACTI128 $1, Y0, X1   // extract high 128 bits from Y0 to X1
    VPADDQ X0, X1, X0         // X0 + X1
    VPSHUFD $0b11101110, X0, X1  // move high 64 bits to low
    VPADDQ X0, X1, X0         // X0 + X1
    VMOVQ X0, AX              // store result to AX

remainder:
    // process remain number (less than 8)
    CMPQ CX, $0
    JE   done

    // start loop to process remain numbers using POPCNTQ
    XORQ DX, DX
remainder_loop:
    POPCNTQ (SI), DX
    ADDQ DX, AX
    ADDQ $8, SI
    LOOP remainder_loop

done:
    MOVQ AX, ret+24(FP)
    RET
