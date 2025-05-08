#include "textflag.h"

// func hammingPPC64LE(a, b []uint64) int
TEXT ·hammingPPC64LE(SB),NOSPLIT,$0-48
    // Load slice parameters
    MOVD a_base+0(FP), R4    // R4 = &a[0]
    MOVD b_base+24(FP), R5    // R5 = &b[0]
    MOVD a_len+8(FP), R6      // R6 = length
    XOR R7, R7                // R7 = result accumulator (0)

    CMP R6, $0
    BEQ done                  // Handle empty slice case

    // Process 4 elements per iteration (unrolled loop)
    SRD $2, R6, R8            // R8 = loop counter (len/4)
    CMP R8, $0
    BEQ tail                  // Skip if less than 4 elements

    // Initialize constants for vector ops
    MOVD $0, R14              // Zero register
    MTVSRD R14, VS32          // Clear VS32 (vector 0)

loop:
    // Load 4 elements (32 bytes) from each slice
    LXVD2X (R4)(R0), VS34     // VS34 = a[0..1]
    LXVD2X (R5)(R0), VS35     // VS35 = b[0..1]
    LXVD2X (R4)(R16), VS36    // VS36 = a[2..3] (R16 must be 16)
    LXVD2X (R5)(R16), VS37    // VS37 = b[2..3]

    // Compute XOR between vectors
    XXLOR VS34, VS35, VS38    // VS38 = a[0..1] ^ b[0..1]
    XXLOR VS36, VS37, VS39    // VS39 = a[2..3] ^ b[2..3]

    // Extract each uint64 and count bits
    MFVSRD VS38, R9           // First element
    POPCNTD R9, R9            // Count bits
    ADD R9, R7, R7            // Accumulate

    MFVSRLD VS38, R10         // Second element
    POPCNTD R10, R10
    ADD R10, R7, R7

    MFVSRD VS39, R11          // Third element
    POPCNTD R11, R11
    ADD R11, R7, R7

    MFVSRLD VS39, R12         // Fourth element
    POPCNTD R12, R12
    ADD R12, R7, R7

    // Advance pointers
    ADD $32, R4
    ADD $32, R5
    ADD $-4, R6               // Decrement remaining count
    ADD $-1, R8               // Decrement loop counter
    CMP R8, $0
    BGT loop

tail:
    // Process remaining elements (0-3)
    CMP R6, $0
    BEQ done

    // Process 2 elements at a time
    CMP R6, $2
    BLT tail_1

    LXVD2X (R4)(R0), VS34
    LXVD2X (R5)(R0), VS35
    XXLOR VS34, VS35, VS36

    MFVSRD VS36, R9
    POPCNTD R9, R9
    ADD R9, R7, R7

    MFVSRLD VS36, R10
    POPCNTD R10, R10
    ADD R10, R7, R7

    ADD $16, R4
    ADD $16, R5
    ADD $-2, R6

tail_1:
    // Process last element if odd count
    CMP R6, $0
    BEQ done

    MOVD (R4), R9
    XOR (R5), R9
    POPCNTD R9, R9
    ADD R9, R7, R7

done:
    MOVD R7, ret+48(FP)       // Store result
    RET
