#include "textflag.h"

// func indexbytenePPC64(b []byte, x byte) int
TEXT ·indexbytenePPC64(SB),NOSPLIT,$0-40
    MOVD  b_base+0(FP), R3    // R3 = pointer to bytes
    MOVD  b_len+8(FP), R4     // R4 = length of bytes
    MOVBZ x+24(FP), R5        // R5 = byte to search for
    MOVD  $-1, R16            // R16 = default return (-1 not found)
    MOVD  $0, R6              // R6 = current index

    // Broadcast search byte to vector register
    MTVSRD R5, V0            // Load byte to V0[0]
    VSPLTB $0, V0, V0        // Splat byte across all 16 positions

main_loop:
    CMP R6, R4
    BGE not_found            // End of slice reached

    // Load 16 bytes
    LXVB16X (R3)(R6), V1     // V1 = 16 bytes from memory

    // Compare with search byte
    VCMPEQUB V1, V0, V2      // V2 = comparison result mask
    MFVRD V2, R7             // Get lower 64 bits of mask
    MFVSRD V2, R8            // Get upper 64 bits of mask

    // Check for any matches
    OR R7, R8, R9
    CMP R9, $0
    BEQ next_chunk           // No matches in this chunk

    // Find first match position
    CNTLZD R7, R10           // Count leading zeros (lower)
    CMP R7, $0
    ISEL EQ, R8, R7, R11     // If lower was zero, check upper
    ISEL EQ, R10, R11, R12   // Select appropriate position
    ADD R6, R12, R13         // R13 = absolute position

    // Count backslashes before match
    MOVD $0, R14             // Backslash counter
    SUB  $1, R13, R15        // R15 = position - 1

count_loop:
    CMP R15, $0
    BLT count_done           // Reached start of slice
    MOVBZ (R3)(R15), R17     // Load byte
    CMP R17, $0x5C           // Is it backslash?
    BNE count_done
    ADD  $1, R14             // Increment counter
    SUB  $1, R15             // Move backward
    B count_loop

count_done:
    // Check if even number of backslashes
    ANDCC $1, R14, R17
    BEQ found                // If even, found our match

    // Odd number - continue search
    ADD $1, R13, R6          // Start from next byte
    B main_loop

next_chunk:
    ADD $16, R6              // Move to next 16-byte chunk
    B main_loop

found:
    MOVD R13, ret+32(FP)     // Return found position
    RET

not_found:
    MOVD R16, ret+32(FP)     // Return -1
    RET
