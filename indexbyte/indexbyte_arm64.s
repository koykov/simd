#include "textflag.h"

// func indexbyteNEON(b []byte, x byte) int
TEXT ·indexbyteNEON(SB),NOSPLIT,$0-40
    MOVD b_base+0(FP), R0     // R0 = pointer to bytes
    MOVD b_len+8(FP), R1      // R1 = length of bytes
    MOVBU x+24(FP), R2        // R2 = byte to search for
    MOVD $-1, R3              // R3 = default result (-1)
    MOVD $0, R4               // R4 = index

    // Broadcast search byte to all lanes
    DUP V0.B16, R2            // V0 = vector with search byte

loop:
    CMP R4, R1                // Check remaining bytes
    BGE not_found

    // Load 16 bytes
    VLD1 (R0)(R4), [V1.B16]

    // Compare bytes
    CMEQ V1.B16, V0.B16, V2.B16
    // Get bitmask
    UMOV 0, V2.D[0], R5
    UMOV 1, V2.D[0], R6
    ORR R5, R6, R5
    CBZ R5, next

    // Find first match
    RBIT R5, R5               // Reverse bits for CLZ
    CLZ R5, R5                // Count leading zeros
    ADD R4, R5, R3            // Calculate position
    B done

next:
    ADD $16, R4               // Advance index
    B loop

not_found:
    MOVD $-1, R3

done:
    MOVD R3, ret+32(FP)
    RET
