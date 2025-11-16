#include "textflag.h"

// func indextokenRISCV64(b []byte) int
TEXT ·indextokenRISCV64(SB),NOSPLIT,$0-32
    MOV    b_base+0(FP), A0   // A0 = pointer to bytes
    MOV    b_len+8(FP), A1    // A1 = length of bytes
    MOV    $-1, A2            // A2 = default result (-1)
    MOV    $0, A3             // A3 = index

    // Configure VLEN dynamically based on remaining bytes
    MOV    A1, A4
    VSETVLI A4, A4, e8, m1    // Set VL = min(A4, VLMAX), 8-bit elements

    // Broadcast target characters
    MOV    $0x2E, A5
    VMV_V_X V0, A5            // V0 = '.'
    MOV    $0x5B, A5
    VMV_V_X V1, A5            // V1 = '['
    MOV    $0x5D, A5
    VMV_V_X V2, A5            // V2 = ']'
    MOV    $0x40, A5
    VMV_V_X V3, A5            // V3 = '@'

main_loop:
    // Get current vector length
    VSETVLI A6, A1, e8, m1    // A6 = actual VL for this iteration
    BEQ    A6, zero, not_found

    // Load bytes with current VL
    VLE8_V V4, (A0)(A3)

    // Compare and find first match
    VMSEQ_VV V5, V4, V0
    VFIRST_M A7, V5
    BGE     A7, zero, found

    VMSEQ_VV V5, V4, V1
    VFIRST_M A7, V5
    BGE     A7, zero, found

    VMSEQ_VV V5, V4, V2
    VFIRST_M A7, V5
    BGE     A7, zero, found

    VMSEQ_VV V5, V4, V3
    VFIRST_M A7, V5
    BGE     A7, zero, found

    // Advance
    ADD     A6, A3
    SUB     A6, A1
    J       main_loop

found:
    ADD     A3, A7, A2
    J       done

not_found:
    MOV     $-1, A2

done:
    MOV     A2, ret+24(FP)
    RET
