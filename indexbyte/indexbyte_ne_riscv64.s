#include "textflag.h"

// func indexbyteneRISCV64(b []byte, x byte) int
TEXT ·indexbyteneRISCV64(SB),NOSPLIT,$0-40
    MOV    b_base+0(FP), A0   // A0 = pointer to bytes
    MOV    b_len+8(FP), A1    // A1 = length of bytes
    MOV    x+24(FP), A2       // A2 = byte to search for
    MOV    $-1, A7            // A7 = default return (-1)
    MOV    $0, A3             // A3 = index

    // Configure vector parameters (VLEN=128 assumed)
    MOV    $16, A4            // 16 bytes per vector
    VSETVLI A4, A4, e8, m1    // Set vector length, 8-bit elements

    // Splat search byte to vector register
    VMV VX, V1, A2            // Broadcast A2 to all vector elements

main_loop:
    BGEU   A3, A1, not_found  // End of slice reached

    // Load 16 bytes
    VLE8 V0, (A0)(A3)         // Load vector from memory

    // Compare with search byte
    VMSEQ V0, V1, V2          // V2 = mask of matches
    VFIRSTM A6, V2            // Find first set bit in mask
    BLTZ   A6, next_chunk     // No matches found

    // Calculate absolute position
    ADD    A3, A6, A5         // A5 = match position

    // Count backslashes before match
    MOV    $0, T0             // Backslash counter
    ADDI   A5, -1, T1         // T1 = position - 1

count_loop:
    BLT    T1, count_done     // Reached start of slice
    ADD    A0, T1, T2
    LBU    (T2), T3           // Load byte
    ADDI   T3, -0x5C, T4
    BNEZ   T4, count_done     // Not a backslash
    ADDI   T0, 1, T0          // Increment counter
    ADDI   T1, -1, T1         // Move backward
    J      count_loop

count_done:
    // Check if even number of backslashes
    ANDI   T0, 1, T4
    BEQZ   T4, found          // If even, found our match

    // Odd number - continue search
    ADDI   A5, 1, A3          // Start from next byte
    J      main_loop

next_chunk:
    ADD    A3, A4, A3         // Move to next chunk
    J      main_loop

found:
    MOV    A5, ret+32(FP)     // Return found position
    RET

not_found:
    MOV    A7, ret+32(FP)     // Return -1
    RET
