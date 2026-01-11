#include "textflag.h"

// func notSSE2(a []uint64)
TEXT ·notSSE2(SB),NOSPLIT,$0-32
    MOVQ    a_base+0(FP), SI     // SI = &a[0]
    MOVQ    a_len+8(FP), CX      // CX = len(a)

    TESTQ   CX, CX
    JZ      done                 // Check empty array case

    // Create mask with all bits set (0xFFFFFFFFFFFFFFFF)
    PCMPEQB X2, X2              // X2 = all ones (0xFFFFFFFFFFFFFFFF)

    // Calculate number of elements we can process with unrolling
    MOVQ    CX, DX
    SHRQ    $1, DX              // DX = number of 2-element groups
    SHLQ    $1, DX              // DX = len(a) & ^1
    JZ      scalar_tail         // If less than 2 elements, go to tail

    // Main loop (2 elements per iteration)
loop:
    // Load 2 uint64 (16 bytes) from a
    MOVOU   (SI), X0            // X0 = a[0], a[1]

    // Apply bitwise NOT (XOR with all ones)
    PXOR    X2, X0              // X0 = ~a[i] (a[i] XOR all ones)

    // Save result back to a
    MOVOU   X0, (SI)

    // Move to next group of 2 elements
    ADDQ    $16, SI
    SUBQ    $2, CX

    CMPQ    CX, $2
    JAE     loop

scalar_tail:
    TESTQ   CX, CX
    JZ      done

    MOVQ    (SI), AX
    NOTQ    AX                  // NOTQ performs bitwise NOT
    MOVQ    AX, (SI)

done:
    RET

// func notAVX2(a []uint64)
TEXT ·notAVX2(SB),NOSPLIT,$0-32
    MOVQ    a_base+0(FP), SI     // SI = pointer to a[0]
    MOVQ    a_len+8(FP), CX      // CX = length of slice

    TESTQ   CX, CX               // Check if length is zero
    JZ      done                 // Return if empty

    // Create mask with all bits set (0xFFFFFFFFFFFFFFFF) in YMM register
    VPCMPEQB Y2, Y2, Y2         // Y2 = all ones (0xFFFFFFFFFFFFFFFF)

    // Process 4 elements per iteration (YMM registers hold 4 uint64 = 32 bytes)
    MOVQ    CX, DX               // DX = total element count
    ANDQ    $0xFFFFFFFC, DX      // DX = count rounded down to multiple of 4
    JZ      tail_scalar          // If less than 4 elements, handle in scalar loop

    // Main AVX2 loop - process 4 uint64 elements per iteration
avx_loop:
    VMOVDQU (SI), Y0            // Load 4 elements from a: Y0 = a[0..3]

    // Apply bitwise NOT (XOR with all ones)
    VPXOR   Y2, Y0, Y0          // Y0 = ~a[i] (a[i] XOR all ones)

    VMOVDQU Y0, (SI)            // Store result back to a

    ADDQ    $32, SI             // Move pointer forward by 32 bytes (4 elements)
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
    NOTQ    AX                  // AX = ~a[i]
    MOVQ    AX, (SI)            // Store result back

    ADDQ    $8, SI              // Move to next element
    DECQ    CX                  // Decrement counter
    JNZ     scalar_loop         // Continue if more elements

done:
    VZEROUPPER                  // Clear upper bits of YMM registers (AVX requirement)
    RET

// func notAVX512(a []uint64)
TEXT ·notAVX512(SB),NOSPLIT,$0-32
    MOVQ    a_base+0(FP), SI     // SI = pointer to a[0]
    MOVQ    a_len+8(FP), CX      // CX = length of slice

    TESTQ   CX, CX               // Check if length is zero
    JZ      done                 // Return if empty

    // Create mask with all bits set (0xFFFFFFFFFFFFFFFF) in ZMM register
    MOVQ    $-1, AX             // AX = 0xFFFFFFFFFFFFFFFF
    MOVQ    AX, X2              // X2 = all ones
    VPBROADCASTQ X2, Z2         // Broadcast 64-bit value to all 8 elements of Z2

    // Process 8 elements per iteration (ZMM registers hold 8 uint64 = 64 bytes)
    MOVQ    CX, DX               // DX = total element count
    ANDQ    $0xFFFFFFF8, DX      // DX = count rounded down to multiple of 8
    JZ      tail_scalar          // If less than 8 elements, handle in scalar loop

    // Main AVX512 loop - process 8 uint64 elements per iteration
avx512_loop:
    VMOVUPD (SI), Z0            // Load 8 elements from a: Z0 = a[0..7]

    // Apply bitwise NOT (XOR with all ones)
    VPXORQ  Z2, Z0, Z0          // Z0 = ~a[i] (a[i] XOR all ones)

    VMOVUPD Z0, (SI)            // Store result back to a

    ADDQ    $64, SI             // Move pointer forward by 64 bytes (8 elements)
    SUBQ    $8, CX              // Decrease remaining element count
    CMPQ    CX, $8              // Check if at least 8 elements remain
    JGE     avx512_loop         // Continue loop if yes

    // Handle remaining elements (0-7)
tail_scalar:
    TESTQ   CX, CX              // Check if any elements remain
    JZ      done                // Return if none

    // Process remaining elements one by one
scalar_loop:
    MOVQ    (SI), AX            // Load element from a
    NOTQ    AX                  // AX = ~a[i]
    MOVQ    AX, (SI)            // Store result back

    ADDQ    $8, SI              // Move to next element
    DECQ    CX                  // Decrement counter
    JNZ     scalar_loop         // Continue if more elements

done:
    RET
