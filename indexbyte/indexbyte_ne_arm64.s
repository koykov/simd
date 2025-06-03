#include "textflag.h"

// func indexbyteneNEON(b []byte, x byte) int
TEXT ·indexbyteneNEON(SB),NOSPLIT,$0-40
    MOVD b_base+0(FP), R0     // R0 = pointer to bytes
    MOVD b_len+8(FP), R1      // R1 = length of bytes
    MOVBU x+24(FP), R2        // R2 = byte to search for
    MOVD $-1, R8              // R8 = default return (-1 not found)
    MOVD $0, R3               // R3 = index

    // Broadcast search byte to all lanes
    DUP V0.B16, R2            // V0 = [R2,R2,...,R2] (16 bytes)

search_loop:
    CMP R3, R1
    BGE not_found             // End of slice reached

    // Load 16 bytes at a time
    MOVD (R0)(R3), R4         // Base address + offset
    LD1 {V1.16B}, [R4]        // V1 = 16 bytes from memory

    // Compare with search byte
    CMEQ V1.16B, V0.16B, V2.16B  // V2 = comparison result mask
    MOV V2.D[0], R5           // Get lower 64 bits of mask
    MOV V2.D[1], R6           // Get upper 64 bits of mask

    // Check for any matches
    ORR R5, R6, R7
    CBZ R7, next_chunk        // No matches in this chunk

    // Find first match position
    CLZ R5, R9                // Count leading zeros (lower)
    CMP R5, $0
    CSEL EQ, R6, R5, R10      // If lower was zero, check upper
    CSEL EQ, R9, R10, R11     // Select appropriate position
    ADD R3, R11, R12          // R12 = absolute position

    // Count backslashes before match
    MOVD $0, R13              // Backslash counter
    SUB $1, R12, R14          // R14 = position - 1

count_loop:
    CMP R14, $0
    BLT count_done            // Reached start of slice
    MOVBU (R0)(R14), R15      // Load byte
    CMP R15, $0x5C            // Is it backslash?
    BNE count_done
    ADD $1, R13               // Increment counter
    SUB $1, R14               // Move backward
    B count_loop

count_done:
    // Check if even number of backslashes
    AND $1, R13, R15
    CBZ R15, found            // If even, found our match

    // Odd number - continue search
    ADD $1, R12, R3           // Start from next byte
    B search_loop

next_chunk:
    ADD $16, R3               // Move to next 16-byte chunk
    B search_loop

found:
    MOVD R12, ret+32(FP)      // Return found position
    RET

not_found:
    MOVD R8, ret+32(FP)       // Return -1
    RET
