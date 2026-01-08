#include "textflag.h"

// func mergeSSE2(a, b []uint64)
TEXT ·mergeSSE2(SB),NOSPLIT,$0-48
    MOVQ    a_base+0(FP), SI     // SI = &a[0]
    MOVQ    b_base+24(FP), DI    // DI = &b[0]
    MOVQ    a_len+8(FP), CX      // CX = len(a)

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

    // OR + POPCNT for first two elements
    POR     X1, X0              // X0 = a[0:1] | b[0:1]

    // First 64-bit element
    MOVQ    X0, BX
    POPCNTQ BX, BX
    MOVQ    BX, (SI)            // Store result back to a[0]

    // Second 64-bit element
    PEXTRQ  $1, X0, BX
    POPCNTQ BX, BX
    MOVQ    BX, 8(SI)           // Store result back to a[1]

    // OR + POPCNT for next two elements
    POR     X3, X2              // X2 = a[2:3] | b[2:3]

    // Third 64-bit element
    MOVQ    X2, BX
    POPCNTQ BX, BX
    MOVQ    BX, 16(SI)          // Store result back to a[2]

    // Fourth 64-bit element
    PEXTRQ  $1, X2, BX
    POPCNTQ BX, BX
    MOVQ    BX, 24(SI)          // Store result back to a[3]

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
    POR     X1, X0              // X0 = a[0:1] | b[0:1]

    // First 64-bit element
    MOVQ    X0, BX
    POPCNTQ BX, BX
    MOVQ    BX, (SI)

    // Second 64-bit element
    PEXTRQ  $1, X0, BX
    POPCNTQ BX, BX
    MOVQ    BX, 8(SI)

    ADDQ    $16, SI
    ADDQ    $16, DI
    SUBQ    $2, CX

scalar_last:
    // Process last element (if odd count)
    TESTQ   CX, CX
    JZ      done

    MOVQ    (SI), BX
    MOVQ    (DI), DX
    ORQ     DX, BX              // BX = a[i] | b[i]
    POPCNTQ BX, BX
    MOVQ    BX, (SI)            // Store result back to a[i]

done:
    RET
