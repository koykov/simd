#include "textflag.h"

// func eoqsSSE2(b []byte) int
TEXT ·eoqsSSE2(SB),NOSPLIT,$0-28
    MOVQ b_base+0(FP), SI     // SI = pointer to data
    MOVQ b_len+8(FP), CX      // CX = length (always multiple of 64)
    XORQ AX, AX               // AX = current position

    // Prepare constants
    MOVQ $0x2222222222222222, BX  // BX = 8x '"'
    MOVQ BX, X7
    PUNPCKLBW X7, X7
    PUNPCKLBW X7, X7           // X7 = 16x '"'

block_loop:
    MOVOU (SI), X0            // Load 16 bytes
    PCMPEQB X7, X0            // Compare with quotes
    PMOVMSKB X0, DX           // DX = mask of quotes

    TESTL DX, DX
    JZ next_block             // If no quotes found

find_quotes:
    BSFQ DX, BX               // Find first quote position in block
    ADDQ BX, AX               // Calculate absolute position

    // Check if quote is escaped
    TESTQ BX, BX              // Is quote at position 0 in block?
    JZ check_first_byte       // Special case for first byte

    LEAQ -1(SI)(BX*1), DI     // DI = address of byte before quote
    CMPB (DI), $0x5C          // Is it backslash?
    JNE unescaped_quote       // If not, we found our quote

    // Quote is escaped, continue search
    ADDQ $1, AX               // Skip this quote
    ADDQ $1, BX               // Move to next position in block
    BTRQ BX, DX               // Clear current bit in mask
    JNZ find_quotes           // Check next quote in same block
    JMP next_block

check_first_byte:
    // Special case: quote is first byte in block
    // Check if it's first byte in entire slice
    TESTQ AX, AX
    JZ unescaped_quote        // If it's start of slice, can't be escaped

    // Check last byte of previous block
    MOVB -1(SI), BL
    CMPB BL, $0x5C            // Is it backslash?
    JNE unescaped_quote

    // Quote is escaped, continue search
    ADDQ $1, AX               // Skip this quote
    ADDQ $1, BX               // Move to next position in block
    BTRQ BX, DX               // Clear current bit in mask
    JNZ find_quotes           // Check next quote in same block

next_block:
    ADDQ $16, SI              // Move to next block
    ADDQ $16, AX
    SUBQ $16, CX
    JNZ block_loop            // Continue while CX > 0

    MOVQ $-1, ret+24(FP)      // Not found
    RET

unescaped_quote:
    MOVQ AX, ret+24(FP)       // Return found position
    RET
