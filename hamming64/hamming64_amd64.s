#include "textflag.h"

// func hammingSSE2(a, b []uint64) int
TEXT ·hammingSSE2(SB),NOSPLIT,$0-48
    MOVQ    a_base+0(FP), SI     // SI = &a[0]
    MOVQ    b_base+24(FP), DI    // DI = &b[0]
    MOVQ    a_len+8(FP), CX      // CX = len(a)
    XORQ    AX, AX               // AX = 0 (accumulator)

    TESTQ   CX, CX
    JZ      done                 // Check empty array case

    // Calculate number of elements we can process with unrolling (CX / 4 * 4)
    MOVQ    CX, DX
    SHRQ    $2, DX              // DX = number of 4-element groups
    SHLQ    $2, DX              // DX *= 4 (now DX = len(a) & ^3)
    JZ      tail                // If less than 4 elements, go to tail

    // Main loop (4 elements per iteration)
loop:
    // Load 4 uint64 (32 bytes) from a and b
    MOVOU   (SI), X0            // a[0], a[1]
    MOVOU   (DI), X1            // b[0], b[1]
    MOVOU   16(SI), X2          // a[2], a[3]
    MOVOU   16(DI), X3          // b[2], b[3]

    // XOR + POPCNT for first two elements
    PXOR    X0, X1              // X1 = a[0:1] ^ b[0:1]
    MOVQ    X1, BX              // Lower 64 bits -> BX
    POPCNTQ BX, BX
    ADDQ    BX, AX
    PEXTRQ  $1, X1, BX          // Upper 64 bits -> BX
    POPCNTQ BX, BX
    ADDQ    BX, AX

    // XOR + POPCNT for next two elements
    PXOR    X2, X3              // X3 = a[2:3] ^ b[2:3]
    MOVQ    X3, BX
    POPCNTQ BX, BX
    ADDQ    BX, AX
    PEXTRQ  $1, X3, BX
    POPCNTQ BX, BX
    ADDQ    BX, AX

    // Move to next group of 4 elements
    ADDQ    $32, SI
    ADDQ    $32, DI
    SUBQ    $4, CX
    CMPQ    CX, $4
    JAE     loop

tail:
    // Process remaining elements (0..3)
    TESTQ   CX, CX
    JZ      done

    // Process 2 elements (if >= 2 remaining)
    CMPQ    CX, $2
    JB      scalar_last

    MOVOU   (SI), X0
    MOVOU   (DI), X1
    PXOR    X0, X1
    MOVQ    X1, BX
    POPCNTQ BX, BX
    ADDQ    BX, AX
    PEXTRQ  $1, X1, BX
    POPCNTQ BX, BX
    ADDQ    BX, AX

    ADDQ    $16, SI
    ADDQ    $16, DI
    SUBQ    $2, CX

scalar_last:
    // Process last element (if odd count)
    TESTQ   CX, CX
    JZ      done

    MOVQ    (SI), BX
    XORQ    (DI), BX
    POPCNTQ BX, BX
    ADDQ    BX, AX

done:
    MOVQ    AX, ret+48(FP)
    RET

// func hammingAVX2(a, b []uint64) int
TEXT ·hammingAVX2(SB),NOSPLIT,$0-48
    MOVQ a_base+0(FP), SI
    MOVQ b_base+24(FP), DI
    MOVQ a_len+8(FP), CX
    XORQ AX, AX

    TESTQ CX, CX
    JZ done

    // Process 8 elements per iteration
    MOVQ CX, DX
    SHRQ $3, DX
    JZ tail_4

loop_8:
    // Load 8 elements (64 bytes)
    VMOVDQU (SI), Y0
    VMOVDQU 32(SI), Y1
    VMOVDQU (DI), Y2
    VMOVDQU 32(DI), Y3

    // Calculate XOR
    VPXOR Y0, Y2, Y4
    VPXOR Y1, Y3, Y5

    // Process first 4 elements (Y4)
    VMOVQ X4, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X4, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VEXTRACTI128 $1, Y4, X6
    VMOVQ X6, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X6, BX
    POPCNTQ BX, BX
    ADDQ BX, AX

    // Process next 4 elements (Y5)
    VMOVQ X5, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X5, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VEXTRACTI128 $1, Y5, X7
    VMOVQ X7, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X7, BX
    POPCNTQ BX, BX
    ADDQ BX, AX

    // Move to next group
    ADDQ $64, SI
    ADDQ $64, DI
    SUBQ $8, CX
    CMPQ CX, $8
    JAE loop_8

tail_4:
    // Remaining 4-7 elements
    CMPQ CX, $4
    JB tail_2

    VMOVDQU (SI), Y0
    VMOVDQU (DI), Y1
    VPXOR Y0, Y1, Y2

    VMOVQ X2, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X2, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VEXTRACTI128 $1, Y2, X3
    VMOVQ X3, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X3, BX
    POPCNTQ BX, BX
    ADDQ BX, AX

    ADDQ $32, SI
    ADDQ $32, DI
    SUBQ $4, CX

tail_2:
    // Remaining 1-3 elements
    CMPQ CX, $2
    JB tail_1

    VMOVDQU (SI), X0
    VMOVDQU (DI), X1
    VPXOR X0, X1, X2

    VMOVQ X2, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X2, BX
    POPCNTQ BX, BX
    ADDQ BX, AX

    ADDQ $16, SI
    ADDQ $16, DI
    SUBQ $2, CX

tail_1:
    TESTQ CX, CX
    JZ done

    MOVQ (SI), BX
    XORQ (DI), BX
    POPCNTQ BX, BX
    ADDQ BX, AX

done:
    VZEROUPPER
    MOVQ AX, ret+48(FP)
    RET

// func hammingAVX512(a, b []uint64) int
TEXT ·hammingAVX512(SB),NOSPLIT,$0-48
    MOVQ a_base+0(FP), SI     // Pointer to array a
    MOVQ b_base+24(FP), DI    // Pointer to array b
    MOVQ a_len+8(FP), CX      // Length of arrays
    XORQ AX, AX               // Result accumulator

    TESTQ CX, CX
    JZ done                   // Check empty array case

    // Process 8 elements per iteration (512 bits)
    MOVQ CX, DX
    SHRQ $3, DX               // DX = count / 8
    JZ tail                   // Skip if less than 8 elements

loop:
    // Load 8 elements (64 bytes)
    VMOVDQU64 (SI), Z0
    VMOVDQU64 (DI), Z1

    // Bitwise XOR
    VPXORQ Z0, Z1, Z2

    // Count bits using AVX-512's VPOPCNTQ
    VPOPCNTQ Z2, Z3           // Z3 contains popcounts for each qword

    // Horizontal sum of counts
    VEXTRACTI64X4 $1, Z3, Y4  // Extract upper 256 bits
    VPADDQ Y3, Y4, Y5         // Sum upper and lower halves
    VEXTRACTI128 $1, Y5, X6
    VPADDQ X5, X6, X7
    VPSHUFD $0xE, X7, X8
    VPADDQ X7, X8, X9
    VMOVQ X9, BX
    ADDQ BX, AX

    // Move to next block
    ADDQ $64, SI
    ADDQ $64, DI
    SUBQ $8, CX
    CMPQ CX, $8
    JAE loop

tail:
    // Handle remaining elements (0-7)
    TESTQ CX, CX
    JZ done

    // Use AVX2 version for tail processing
    CMPQ CX, $4
    JB tail_2

    // Process 4 elements
    VMOVDQU (SI), Y0
    VMOVDQU (DI), Y1
    VPXOR Y0, Y1, Y2

    VMOVQ X2, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X2, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VEXTRACTI128 $1, Y2, X3
    VMOVQ X3, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X3, BX
    POPCNTQ BX, BX
    ADDQ BX, AX

    ADDQ $32, SI
    ADDQ $32, DI
    SUBQ $4, CX

tail_2:
    // Handle remaining 0-3 elements
    CMPQ CX, $2
    JB tail_1

    // Process 2 elements
    VMOVDQU (SI), X0
    VMOVDQU (DI), X1
    VPXOR X0, X1, X2

    VMOVQ X2, BX
    POPCNTQ BX, BX
    ADDQ BX, AX
    VPEXTRQ $1, X2, BX
    POPCNTQ BX, BX
    ADDQ BX, AX

    ADDQ $16, SI
    ADDQ $16, DI
    SUBQ $2, CX

tail_1:
    TESTQ CX, CX
    JZ done

    // Process last element
    MOVQ (SI), BX
    XORQ (DI), BX
    POPCNTQ BX, BX
    ADDQ BX, AX

done:
    VZEROUPPER
    MOVQ AX, ret+48(FP)
    RET
