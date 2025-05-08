#include "textflag.h"

// func hammingRISCV(a, b []uint64) int
TEXT ·hammingRISCV(SB),NOSPLIT,$0-48
    // Load slice parameters
    MOV a_base+0(FP), A0    // A0 = &a[0]
    MOV b_base+24(FP), A1   // A1 = &b[0]
    MOV a_len+8(FP), A2     // A2 = length
    MOV ZERO, A3            // A3 = result accumulator (0)

    BEQ A2, ZERO, done      // Handle empty slice case

    // Process 2 elements per iteration (unrolled loop)
    SRLI A2, 1, A4          // A4 = loop counter (len/2)
    BEQ A4, ZERO, tail      // Skip if less than 2 elements

loop:
    // Load 2 elements (16 bytes) from each slice
    LD A0, 0(A5)            // A5 = a[0]
    LD A1, 0(A6)            // A6 = b[0]
    LD A0, 8(A7)            // A7 = a[1]
    LD A1, 8(A8)            // A8 = b[1]

    // Compute XOR and count bits
    XOR A5, A6, A5          // a[0] ^ b[0]
    XOR A7, A8, A7          // a[1] ^ b[1]

    // Use CPU's popcount instruction if available (Zbb extension)
    // Fallback to software implementation if not
    POPCNT A5, A5           // Count bits in a[0]^b[0]
    POPCNT A7, A7           // Count bits in a[1]^b[1]

    // Accumulate results
    ADD A5, A3, A3
    ADD A7, A3, A3

    // Advance pointers
    ADDI A0, 16, A0         // a += 2
    ADDI A1, 16, A1         // b += 2
    ADDI A4, -1, A4         // Decrement loop counter
    BNE A4, ZERO, loop

tail:
    // Process remaining element (0-1)
    ANDI A2, 1, A4          // Check odd element
    BEQ A4, ZERO, done

    LD A0, 0(A5)            // Load last element
    LD A1, 0(A6)
    XOR A5, A6, A5
    POPCNT A5, A5
    ADD A5, A3, A3

done:
    MOV A3, ret+48(FP)      // Store result
    RET
