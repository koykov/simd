#include "textflag.h"

// func skiplineNEON(b []byte) int
// Requires: len(b) % 64 == 0, ARM64 with NEON
TEXT ·skiplineNEON(SB),NOSPLIT,$0-32
    MOVD b_base+0(FP), R0   // R0 = data pointer
    MOVD b_len+8(FP), R1    // R1 = length (must be %64 == 0)
    MOVD $-1, R2            // Default return = -1

    CBZ R1, done            // Early exit if empty slice

    // Load constants:
    // Q0 = 16 bytes of 0x0A ('\n')
    // Q1 = 16 bytes of 0x0D ('\r')
    MOVD $0x0A0A0A0A0A0A0A0A, R3
    MOVD R3, V0.D[0]
    MOVD R3, V0.D[1]        // Q0 = \n\n\n\n...

    MOVD $0x0D0D0D0D0D0D0D0D, R4
    MOVD R4, V1.D[0]
    MOVD R4, V1.D[1]        // Q1 = \r\r\r\r...

    MOVD R0, R5             // R5 = current pointer

loop:
    // Load 64 bytes (4x16)
    LD1 {V16.16B-V19.16B}, [R5], #64 // Load 4 Q registers

    // Compare with '\n'
    CMEQ V16.16B, V0.16B, V20.16B
    CMEQ V17.16B, V0.16B, V21.16B
    CMEQ V18.16B, V0.16B, V22.16B
    CMEQ V19.16B, V0.16B, V23.16B

    // Compare with '\r'
    CMEQ V16.16B, V1.16B, V24.16B
    CMEQ V17.16B, V1.16B, V25.16B
    CMEQ V18.16B, V1.16B, V26.16B
    CMEQ V19.16B, V1.16B, V27.16B

    // Combine results
    ORR V20.16B, V24.16B, V20.16B
    ORR V21.16B, V25.16B, V21.16B
    ORR V22.16B, V26.16B, V22.16B
    ORR V23.16B, V27.16B, V23.16B

    // Check for matches
    ADDV B20, V20.16B       // Horizontal sum of bits
    MOV V20.B[0], R6
    CBNZ R6, found_block1

    ADDV B21, V21.16B
    MOV V21.B[0], R6
    CBNZ R6, found_block2

    ADDV B22, V22.16B
    MOV V22.B[0], R6
    CBNZ R6, found_block3

    ADDV B23, V23.16B
    MOV V23.B[0], R6
    CBNZ R6, found_block4

    SUBS R1, R1, #64        // Decrement counter
    B.NE loop               // Continue if bytes remain

not_found:
    MOVD $-1, R2
    B done

found_block1:
    SUB R5, R5, #64         // Reset to start of block
    RBIT V20.16B, V20.16B   // Reverse bits for CLZ
    CLZ V20.16B, V20.16B    // Count leading zeros
    MOV V20.B[0], R6        // Get position
    B calc_pos

found_block2:
    SUB R5, R5, #48         // Point to start of block 2
    RBIT V21.16B, V21.16B
    CLZ V21.16B, V21.16B
    MOV V21.B[0], R6
    ADD R6, R6, #16         // Add block offset
    B calc_pos

found_block3:
    SUB R5, R5, #32         // Point to start of block 3
    RBIT V22.16B, V22.16B
    CLZ V22.16B, V22.16B
    MOV V22.B[0], R6
    ADD R6, R6, #32         // Add block offset
    B calc_pos

found_block4:
    SUB R5, R5, #16         // Point to start of block 4
    RBIT V23.16B, V23.16B
    CLZ V23.16B, V23.16B
    MOV V23.B[0], R6
    ADD R6, R6, #48         // Add block offset

calc_pos:
    SUB R0, R5, R7          // R7 = block offset from start
    ADD R7, R6, R2          // R2 = total offset

done:
    MOVD R2, ret+24(FP)
    RET
