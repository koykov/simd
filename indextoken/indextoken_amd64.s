#include "textflag.h"

// func indextokenSSE2(b []byte) int
TEXT ·indextokenSSE2(SB), NOSPLIT, $0-32
    MOVQ b_base+0(FP), SI     // SI = pointer to slice data
    MOVQ b_len+8(FP), CX      // CX = slice length
    XORQ AX, AX               // AX = current index

    // Check for empty slice
    TESTQ CX, CX
    JZ    not_found

    // Load masks for target characters
    // '.' = 0x2E, '[' = 0x5B, ']' = 0x5D, '@' = 0x40
    MOVOU ·mask0(SB), X0      // Load first mask ('.' and '[')
    MOVOU ·mask1(SB), X1      // Load second mask (']' and '@')

main_loop:
    CMPQ CX, $16
    JB   tail_processing

    // Load 16 bytes
    MOVOU (SI), X2

    // Compare with first mask characters
    MOVOU X2, X3
    PCMPEQB X0, X3           // Compare with '.' and '['
    PMOVMSKB X3, DX
    TESTL DX, DX
    JNZ   found_in_block

    // Compare with second mask characters
    MOVOU X2, X3
    PCMPEQB X1, X3           // Compare with ']' and '@'
    PMOVMSKB X3, DX
    TESTL DX, DX
    JNZ   found_in_block

    // Move to next block
    ADDQ $16, SI
    ADDQ $16, AX
    SUBQ $16, CX
    JMP  main_loop

tail_processing:
    // Process remaining bytes
    TESTQ CX, CX
    JZ    not_found

    MOVQ SI, DI              // DI = current pointer
    MOVQ CX, DX              // DX = bytes left to check

tail_loop:
    MOVB (DI), BL
    CMPB BL, $0x2E           // '.'
    JE   found_tail
    CMPB BL, $0x5B           // '['
    JE   found_tail
    CMPB BL, $0x5D           // ']'
    JE   found_tail
    CMPB BL, $0x40           // '@'
    JE   found_tail

    INCQ DI
    DECQ DX
    JNZ  tail_loop
    JMP  not_found

found_in_block:
    // Find position within current block
    BSFW DX, DX              // DX = position in current block
    ADDQ DX, AX              // Add block offset
    JMP  done

found_tail:
    // Calculate position for tail
    MOVQ DI, AX
    SUBQ b_base+0(FP), AX    // AX = DI - base
    JMP  done

not_found:
    MOVQ $-1, AX

done:
    MOVQ AX, ret+24(FP)
    RET

// Mask data
DATA ·mask0+0(SB)/8, $0x2E5B2E5B2E5B2E5B  // '.' and '[' alternating
DATA ·mask0+8(SB)/8, $0x2E5B2E5B2E5B2E5B
DATA ·mask1+0(SB)/8, $0x405D405D405D405D  // '@' and ']' alternating
DATA ·mask1+8(SB)/8, $0x405D405D405D405D
GLOBL ·mask0(SB), (NOPTR+RODATA), $16
GLOBL ·mask1(SB), (NOPTR+RODATA), $16
