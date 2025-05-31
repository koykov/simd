#include "textflag.h"

// func indexbytePPC64LE(b []byte, x byte) int
TEXT ·indexbytePPC64LE(SB),NOSPLIT,$0-40
    MOVD  b_base+0(FP), R3    // R3 = pointer to bytes
    MOVD  b_len+8(FP), R4     // R4 = length of bytes
    MOVBZ x+24(FP), R5        // R5 = byte to search for
    MOVD  $-1, R6             // R6 = default result (-1)
    MOVD  $0, R7              // R7 = index

    // Broadcast search byte to all 16 positions
    MTVSRD R5, V0             // Load byte into VSR[0]
    VSPLTB V0, 0, V0          // Splat byte across all 16 lanes

loop:
    CMP R7, R4                // Check remaining bytes
    BGE not_found

    // Load 16 bytes
    LXVB16X (R3)(R7), V1      // Load 16 bytes into V1

    // Compare bytes (vector equal)
    VCMPEQUB V1, V0, V2       // V2 = comparison result mask

    // Extract bitmask (move to GPR)
    MFVSRD V2, R8             // Get lower 64 bits of mask
    MFVSRLD V2, R9            // Get upper 64 bits of mask
    OR R8, R9, R8             // Combine both parts
    CMP R8, $0                // Check for any matches
    BEQ next                  // If no matches, continue

    // Find first set bit (cntlzd + subtraction)
    CNTLZD R8, R9             // Count leading zeros
    SUB $63, R9, R9           // Calculate position (PPC bit numbering)
    ADD R7, R9, R6            // Add base offset
    B done

next:
    ADD $16, R7               // Advance index by 16
    B loop

not_found:
    MOVD $-1, R6

done:
    MOVD R6, ret+32(FP)
    RET
