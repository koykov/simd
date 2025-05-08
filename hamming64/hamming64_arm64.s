#include "textflag.h"

// func hammingNEON(a, b []uint64) int
TEXT ·hammingNEON(SB),NOSPLIT,$0-48
    // Load slice parameters
    MOVD a_base+0(FP), R0    // R0 = &a[0]
    MOVD b_base+24(FP), R1   // R1 = &b[0]
    MOVD a_len+8(FP), R2     // R2 = length
    MOVD $0, R3              // R3 = result accumulator (0)

    CBZ R2, done             // Handle empty slice case

    // Process 4 elements per iteration (unrolled loop)
    LSR $2, R2, R4           // R4 = loop counter (len/4)
    CBZ R4, tail             // Skip if less than 4 elements

loop:
    // Load 4 elements (32 bytes) from each slice
    LDP.P (R0), (R5, R6)     // Load a[0], a[1] and advance R0
    LDP.P (R1), (R7, R8)     // Load b[0], b[1] and advance R1
    LDP.P (R0), (R9, R10)    // Load a[2], a[3]
    LDP.P (R1), (R11, R12)   // Load b[2], b[3]

    // Compute XOR and count bits
    EOR R5, R7, R5           // a[0] ^ b[0]
    EOR R6, R8, R6           // a[1] ^ b[1]
    EOR R9, R11, R9          // a[2] ^ b[2]
    EOR R10, R12, R10        // a[3] ^ b[3]

    CNT R5, R5               // Count bits (v8.1-A+)
    CNT R6, R6
    CNT R9, R9
    CNT R10, R10

    // Accumulate results
    ADD R5, R3, R3
    ADD R6, R3, R3
    ADD R9, R3, R3
    ADD R10, R3, R3

    // Decrement and loop
    SUBS $1, R4, R4          // Decrement loop counter
    B.NE loop

tail:
    // Process remaining elements (0-3)
    CBZ R2, done

    // Process 2 elements at a time
    CMP R2, $2
    B.LT tail_1

    LDP.P (R0), (R5, R6)     // Load a[0], a[1]
    LDP.P (R1), (R7, R8)     // Load b[0], b[1]

    EOR R5, R7, R5
    EOR R6, R8, R6
    CNT R5, R5
    CNT R6, R6
    ADD R5, R3, R3
    ADD R6, R3, R3

    SUB $2, R2, R2           // Decrement remaining count

tail_1:
    // Process last element if odd count
    CBZ R2, done

    MOVD (R0), R5
    MOVD (R1), R6
    EOR R5, R6, R5
    CNT R5, R5
    ADD R5, R3, R3

done:
    MOVD R3, ret+48(FP)      // Store result
    RET
