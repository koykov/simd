#include "textflag.h"

// func indextokenSSE2(b []byte) int
TEXT ·indextokenSSE2(SB),NOSPLIT,$0-32
    MOVQ b_base+0(FP), SI     // SI = pointer to bytes
    MOVQ b_len+8(FP), CX      // CX = length of bytes
    XORQ DX, DX               // DX = index (will be returned)

    // Broadcast '.' to X0
    MOVL $0x2E2E2E2E, AX
    MOVD AX, X0
    PSHUFL $0, X0, X0         // X0 = all bytes = '.'

    // Broadcast '[' to X1
    MOVL $0x5B5B5B5B, AX
    MOVD AX, X1
    PSHUFL $0, X1, X1         // X1 = all bytes = '['

    // Broadcast ']' to X2
    MOVL $0x5D5D5D5D, AX
    MOVD AX, X2
    PSHUFL $0, X2, X2         // X2 = all bytes = ']'

    // Broadcast '@' to X3
    MOVL $0x40404040, AX
    MOVD AX, X3
    PSHUFL $0, X3, X3         // X3 = all bytes = '@'

main_loop:
    CMPQ DX, CX
    JAE not_found

    // Load 16 bytes
    MOVOU (SI)(DX*1), X4

    // Compare with each target character
    MOVOU X4, X5
    PCMPEQB X0, X5            // Compare with '.'
    PMOVMSKB X5, BX
    TESTL BX, BX
    JNZ found

    MOVOU X4, X5
    PCMPEQB X1, X5            // Compare with '['
    PMOVMSKB X5, BX
    TESTL BX, BX
    JNZ found

    MOVOU X4, X5
    PCMPEQB X2, X5            // Compare with ']'
    PMOVMSKB X5, BX
    TESTL BX, BX
    JNZ found

    MOVOU X4, X5
    PCMPEQB X3, X5            // Compare with '@'
    PMOVMSKB X5, BX
    TESTL BX, BX
    JNZ found

    // No match, move to next block
    ADDQ $16, DX
    JMP main_loop

found:
    // Find the position of the first set bit
    BSFL BX, BX               // BX = position in current block (0-15)
    ADDQ BX, DX               // DX = total position
    CMPQ DX, CX               // Check if position is within bounds
    JB store_result
    MOVQ $-1, DX              // If beyond bounds, return -1

store_result:
    MOVQ DX, ret+24(FP)
    RET

not_found:
    MOVQ $-1, ret+24(FP)
    RET

// func indextokenAVX2(b []byte) int
TEXT ·indextokenAVX2(SB),NOSPLIT,$0-32
    MOVQ b_base+0(FP), SI     // SI = pointer to bytes
    MOVQ b_len+8(FP), CX      // CX = length of bytes
    XORQ DX, DX               // DX = index (will be returned)

    // Broadcast '.' to Y0
    MOVL $0x2E, AX            // '.' = 0x2E
    MOVD AX, X0
    VPBROADCASTB X0, Y0       // Y0 = all bytes = '.'

    // Broadcast '[' to Y1
    MOVL $0x5B, AX            // '[' = 0x5B
    MOVD AX, X1
    VPBROADCASTB X1, Y1       // Y1 = all bytes = '['

    // Broadcast ']' to Y2
    MOVL $0x5D, AX            // ']' = 0x5D
    MOVD AX, X2
    VPBROADCASTB X2, Y2       // Y2 = all bytes = ']'

    // Broadcast '@' to Y3
    MOVL $0x40, AX            // '@' = 0x40
    MOVD AX, X3
    VPBROADCASTB X3, Y3       // Y3 = all bytes = '@'

main_loop:
    CMPQ DX, CX
    JAE not_found

    // Load 32 bytes
    VMOVDQU (SI)(DX*1), Y4

    // Compare with each target character
    VPCMPEQB Y0, Y4, Y5       // Compare with '.'
    VPMOVMSKB Y5, BX
    TESTL BX, BX
    JNZ found

    VPCMPEQB Y1, Y4, Y5       // Compare with '['
    VPMOVMSKB Y5, BX
    TESTL BX, BX
    JNZ found

    VPCMPEQB Y2, Y4, Y5       // Compare with ']'
    VPMOVMSKB Y5, BX
    TESTL BX, BX
    JNZ found

    VPCMPEQB Y3, Y4, Y5       // Compare with '@'
    VPMOVMSKB Y5, BX
    TESTL BX, BX
    JNZ found

    // No match, move to next block
    ADDQ $32, DX
    JMP main_loop

found:
    // Find the position of the first set bit
    BSFL BX, BX               // BX = position in current block (0-31)
    ADDQ BX, DX               // DX = total position
    CMPQ DX, CX               // Check if position is within bounds
    JB store_result
    MOVQ $-1, DX              // If beyond bounds, return -1

store_result:
    VZEROUPPER                // Clear upper bits of YMM registers
    MOVQ DX, ret+24(FP)
    RET

not_found:
    VZEROUPPER                // Clear upper bits of YMM registers
    MOVQ $-1, ret+24(FP)
    RET

