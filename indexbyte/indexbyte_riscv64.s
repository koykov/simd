#include "textflag.h"

// func indexbyteRISCV64(b []byte, x byte) int
TEXT ·indexbyteRISCV64(SB),NOSPLIT,$0-40
    MOV    b_base+0(FP), A0   // A0 = pointer to bytes
    MOV    b_len+8(FP), A1    // A1 = length of bytes
    MOV    x+24(FP), A2       // A2 = byte to search for
    MOV    $-1, A3            // A3 = default result (-1)
    MOV    $0, A4             // A4 = index

    // Configure VLEN (assumes VLEN=128 for example)
    MOV    $16, A5            // 16 bytes per vector (128-bit)
    VSETVLI A5, A5, e8, m1    // Set vector length: 8-bit elements, mask in m1

    // Splat search byte to vector
    VMV_V_X V0, A2            // Broadcast byte to all lanes

loop:
    // Check remaining bytes
    SUB    A1, A4, A6
    BLE    A6, not_found

    // Load vector (segmented load if needed)
    VLE8_V V1, (A0)(A4)      // Load 16 bytes

    // Compare bytes
    VMSEQ_VV V2, V1, V0      // V2[i] = (V1[i] == V0[i])
    // Get first match
    VFIRST_M A5, V2          // A5 = index of first set bit in mask
    BGE    A5, zero, found   // If found (A5 >= 0)

    // Advance index
    ADD    A5, A4, A4        // A5 contains VL
    J      loop

found:
    ADD    A4, A5, A3        // A4 = base, A5 = offset
    J      done

not_found:
    MOV    $-1, A3

done:
    MOV    A3, ret+32(FP)
    RET
