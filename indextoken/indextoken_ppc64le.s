#include "textflag.h"

// func indextokenPPC64LE(b []byte) int
TEXT ·indextokenPPC64LE(SB),NOSPLIT,$0-32
    MOVD  b_base+0(FP), R3    // R3 = pointer to bytes
    MOVD  b_len+8(FP), R4     // R4 = length of bytes
    MOVD  $-1, R5             // R5 = default result (-1)
    MOVD  $0, R6              // R6 = index

    // Broadcast target characters
    MOVD  $0x2E, R7           // '.'
    MTVSRD R7, V0
    VSPLTB V0, 0, V0
    MOVD  $0x5B, R7           // '['
    MTVSRD R7, V1
    VSPLTB V1, 0, V1
    MOVD  $0x5D, R7           // ']'
    MTVSRD R7, V2
    VSPLTB V2, 0, V2
    MOVD  $0x40, R7           // '@'
    MTVSRD R7, V3
    VSPLTB V3, 0, V3

main_loop:
    CMP R6, R4
    BGE not_found

    // Load 16 bytes
    LXVB16X (R3)(R6), V4

    // Compare with all targets and combine results with OR
    VCMPEQUB V4, V0, V5       // Compare with '.'
    VCMPEQUB V4, V1, V6       // Compare with '['
    XXLOR V5, V6, V5          // V5 = V5 | V6
    VCMPEQUB V4, V2, V6       // Compare with ']'
    XXLOR V5, V6, V5          // V5 = V5 | V6
    VCMPEQUB V4, V3, V6       // Compare with '@'
    XXLOR V5, V6, V5          // V5 = combined mask

    // Get bitmask from combined result
    MFVSRD V5, R8
    MFVSRLD V5, R9
    OR R8, R9, R10
    CMP R10, $0
    BEQ next

    // Find first match
    CNTLZD R10, R11
    SUB $63, R11, R11
    ADD R6, R11, R5
    CMP R5, R4
    BGE not_found
    B done

next:
    ADD $16, R6
    B main_loop

not_found:
    MOVD $-1, R5

done:
    MOVD R5, ret+24(FP)
    RET
