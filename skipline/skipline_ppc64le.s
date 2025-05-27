#include "textflag.h"

// func skiplinePPC64LE(b []byte) int
// Requires: len(b) % 64 == 0
TEXT ·skiplinePPC64LE(SB),NOSPLIT,$0-32
    MOVD b_base+0(FP), R3   // R3 = pointer to data
    MOVD b_len+8(FP), R4    // R4 = length (must be %64 == 0)
    MOVD $-1, R8            // Default return = -1

    CMP R4, $0
    BEQ done                // Empty slice case

    // Load constants:
    // - V0 = 16 bytes of 0x0A (\n)
    // - V1 = 16 bytes of 0x0D (\r)
    MOVD $0x0A0A0A0A0A0A0A0A, R5
    MOVD R5, V0
    VSPLTB $0, V0, V0       // Splat byte across vector

    MOVD $0x0D0D0D0D0D0D0D0D, R6
    MOVD R6, V1
    VSPLTB $0, V1, V1       // Splat byte across vector

    MOVD R3, R7             // R7 = current pointer
    MOVD R4, R9             // R9 = remaining bytes

loop:
    // Load 64 bytes (4x16)
    LXVB16X (R7), VS32      // V2 = 16 bytes
    LXVB16X $16(R7), VS33   // V3 = next 16 bytes
    LXVB16X $32(R7), VS34   // V4
    LXVB16X $48(R7), VS35   // V5

    // Compare with \n
    VCMPEQUB V0, V2, V6     // V6 = mask for \n in block 1
    VCMPEQUB V0, V3, V7     // V7 = mask for \n in block 2
    VCMPEQUB V0, V4, V8     // V8...
    VCMPEQUB V0, V5, V9     // V9...

    // Compare with \r
    VCMPEQUB V1, V2, V10    // V10 = mask for \r in block 1
    VCMPEQUB V1, V3, V11    // V11...
    VCMPEQUB V1, V4, V12    // V12...
    VCMPEQUB V1, V5, V13    // V13...

    // Combine results
    VOR V6, V10, V6         // V6 = combined mask block 1
    VOR V7, V11, V7         // V7 = combined mask block 2
    VOR V8, V12, V8         // V8...
    VOR V9, V13, V9         // V9...

    // Check any match
    VCMEQUBRC V6, V6, V14   // Generate CR6 bits
    BNE cr6, found_block1
    VCMEQUBRC V7, V7, V14
    BNE cr6, found_block2
    VCMEQUBRC V8, V8, V14
    BNE cr6, found_block3
    VCMEQUBRC V9, V9, V14
    BNE cr6, found_block4

    ADD $64, R7             // Move pointer
    SUB $64, R9             // Decrement counter
    BNE loop                // Continue if bytes remain

notfound:
    MOVD $-1, R8
    B done

found_block1:
    VCLZD V6, V6            // Count leading zeros = position
    MFVRD V6, R10
    B calc_pos

found_block2:
    VCLZD V7, V7
    MFVRD V7, R10
    ADD $16, R10            // Add block offset
    B calc_pos

found_block3:
    VCLZD V8, V8
    MFVRD V8, R10
    ADD $32, R10            // Add block offset
    B calc_pos

found_block4:
    VCLZD V9, V9
    MFVRD V9, R10
    ADD $48, R10            // Add block offset

calc_pos:
    SUB R3, R7              // R7 = block offset
    ADD R10, R7             // R7 += in-block position
    MOVD R7, R8             // Return value

done:
    MOVD R8, ret+24(FP)
    RET
