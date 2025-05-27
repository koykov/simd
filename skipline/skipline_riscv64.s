#include "textflag.h"

// func skiplineRISCV64(b []byte) int
// Requires: len(b) % 64 == 0, RV64GCV CPU
TEXT ·skiplineRISCV64(SB),NOSPLIT,$0-32
    MOV b_base+0(FP), A0    // A0 = data pointer
    MOV b_len+8(FP), A1     // A1 = length (must be %64 == 0)
    MOV $-1, A2             // Default return = -1

    BEQZ A1, done           // Empty slice case

    // Set up vector config
    MOV $64, T0             // Set VLEN=64 bytes (max for one iteration)
    MOV $0x0A, T1           // \n byte pattern
    MOV $0x0D, T2           // \r byte pattern

    // Configure vector type (8-bit elements)
    MOV $8, T3              // SEW=8 (byte elements)
    MOV $1, T4              // LMUL=1 (single vector register group)
    VSETVLC T3, T4          // vsetvli x0, x0, e8, m1

main_loop:
    VLE8_V V0, (A0)         // Load 64 bytes into V0-V3 (depends on VLEN)

    // Broadcast search bytes to vector registers
    VMV_V_X V4, T1          // V4 = vector of \n
    VMV_V_X V5, T2          // V5 = vector of \r

    // Compare against both delimiters
    VMSBC_VV V0, V4, V6     // V6 = mask for \n matches
    VMSBC_VV V0, V5, V7     // V7 = mask for \r matches
    VMOR_VV V6, V7, V8      // V8 = combined match mask

    // Check for any matches
    VFIRST_M V8, T5         // Find first set bit (returns -1 if none)
    BGEZ T5, found          // If found, T5 contains position

    ADD $64, A0             // Move pointer
    SUB $64, A1             // Decrement counter
    BNEZ A1, main_loop      // Continue if bytes remain

not_found:
    MOV $-1, A2
    J done

found:
    ADD A0, T5, A2          // Calculate address
    SUB b_base+0(FP), A2    // Convert to offset

done:
    MOV A2, ret+24(FP)
    RET
