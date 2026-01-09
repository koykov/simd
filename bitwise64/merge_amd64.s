#include "textflag.h"

// func mergeSSE2(a, b []uint64)
TEXT ·mergeSSE2(SB),NOSPLIT,$0-48
    MOVQ    a_base+0(FP), SI     // SI = &a[0]
    MOVQ    b_base+24(FP), DI    // DI = &b[0]
    MOVQ    a_len+8(FP), CX      // CX = len(a)

    TESTQ   CX, CX
    JZ      done                 // Check empty array case

    // Calculate number of elements we can process with unrolling
    MOVQ    CX, DX
    SHRQ    $1, DX              // DX = number of 2-element groups
    SHLQ    $1, DX              // DX = len(a) & ^1
    JZ      scalar_tail         // If less than 2 elements, go to tail

    // Main loop (2 elements per iteration)
loop:
    // Load 2 uint64 (16 bytes) from a and b
    MOVOU   (SI), X0            // X0 = a[0], a[1]
    MOVOU   (DI), X1            // X1 = b[0], b[1]

    // Apply bitwise OR
    POR     X1, X0              // X0 = a[i] | b[i]

    // Save result back to a
    MOVOU   X0, (SI)

    // Move to next group of 2 elements
    ADDQ    $16, SI
    ADDQ    $16, DI
    SUBQ    $2, CX

    CMPQ    CX, $2
    JAE     loop

scalar_tail:
    TESTQ   CX, CX
    JZ      done

    MOVQ    (SI), AX
    ORQ     (DI), AX
    MOVQ    AX, (SI)

done:
    RET

// func mergeAVX2(a, b []uint64)
TEXT ·mergeAVX2(SB),NOSPLIT,$0-48
    MOVQ    a_base+0(FP), SI     // SI = pointer to a[0]
    MOVQ    b_base+24(FP), DI    // DI = pointer to b[0]
    MOVQ    a_len+8(FP), CX      // CX = length of slices

    TESTQ   CX, CX               // Check if length is zero
    JZ      done                 // Return if empty

    // Process 4 elements per iteration (YMM registers hold 4 uint64 = 32 bytes)
    MOVQ    CX, DX               // DX = total element count
    ANDQ    $0xFFFFFFFC, DX      // DX = count rounded down to multiple of 4
    JZ      tail_scalar          // If less than 4 elements, handle in scalar loop

    // Main AVX2 loop - process 4 uint64 elements per iteration
avx_loop:
    VMOVDQU (SI), Y0            // Load 4 elements from a: Y0 = a[0..3]
    VMOVDQU (DI), Y1            // Load 4 elements from b: Y1 = b[0..3]

    VPOR    Y0, Y1, Y0          // Y0 = a[i] OR b[i] for all 4 elements
    VMOVDQU Y0, (SI)            // Store result back to a

    ADDQ    $32, SI             // Move pointers forward by 32 bytes (4 elements)
    ADDQ    $32, DI
    SUBQ    $4, CX              // Decrease remaining element count
    CMPQ    CX, $4              // Check if at least 4 elements remain
    JGE     avx_loop            // Continue loop if yes

    // Handle remaining elements (0-3)
tail_scalar:
    TESTQ   CX, CX              // Check if any elements remain
    JZ      done                // Return if none

    // Process remaining elements one by one
scalar_loop:
    MOVQ    (SI), AX            // Load element from a
    ORQ     (DI), AX            // AX = a[i] | b[i]
    MOVQ    AX, (SI)            // Store result back

    ADDQ    $8, SI              // Move to next element
    ADDQ    $8, DI
    DECQ    CX                  // Decrement counter
    JNZ     scalar_loop         // Continue if more elements

done:
    VZEROUPPER                  // Clear upper bits of YMM registers (AVX requirement)
    RET
