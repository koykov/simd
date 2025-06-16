#include "textflag.h"

// func eoqsSSE2(b []byte) int
TEXT ·eoqsSSE2(SB),NOSPLIT,$0-28
    MOVQ b_base+0(FP), SI     // SI = pointer to byte slice data
    MOVQ b_len+8(FP), CX      // CX = length of byte slice
    XORQ AX, AX               // AX = current position (will be result)
    XORQ DX, DX               // DX = escaped state (0 = not escaped)

    // Preload constants
    MOVQ $0x2222222222222222, BX  // BX = 8x quote (")
    MOVQ BX, X7
    PUNPCKLBW X7, X7
    PUNPCKLBW X7, X7           // X7 = 16x quote (")

    MOVQ $0x5C5C5C5C5C5C5C5C, BX  // BX = 8x backslash (\)
    MOVQ BX, X6
    PUNPCKLBW X6, X6
    PUNPCKLBW X6, X6           // X6 = 16x backslash (\)

loop:
    CMPQ CX, $16
    JB small_chunk

    MOVOU (SI), X0            // Load 16 bytes
    ADDQ $16, SI
    SUBQ $16, CX
    ADDQ $16, AX

    // Check for backslashes
    MOVOU X0, X4
    PCMPEQB X6, X4
    PMOVMSKB X4, BX           // BX = backslash mask

    // Check for quotes
    MOVOU X0, X4
    PCMPEQB X7, X4
    PMOVMSKB X4, BP           // BP = quote mask

    // Process escape sequences
    TESTQ BX, BX
    JZ check_quotes

    // Handle backslashes - mark next character as escaped
    MOVQ BX, DI
    SHRQ $1, DI
    XORQ BX, DI               // DI = backslash not followed by backslash
    ANDNQ BP, DI, BP          // Clear quotes that are escaped

check_quotes:
    TESTQ BP, BP
    JZ loop

    // Found potential quote - check if not escaped
    TESTQ DX, DX
    JNZ loop                 // Skip if in escaped state

    BSFQ BP, BP              // Find first quote
    LEAQ -16(AX)(BP*1), AX   // Calculate position
    JMP return

small_chunk:
    TESTQ CX, CX
    JZ not_found

    MOVB (SI), BL
    CMPB BL, $0x5C           // backslash
    JE handle_backslash
    CMPB BL, $0x22           // quote
    JE handle_quote

    INCQ SI
    INCQ AX
    DECQ CX
    JMP small_chunk

handle_backslash:
    // Set escaped state for next character
    MOVQ $1, DX
    INCQ SI
    INCQ AX
    DECQ CX
    JMP small_chunk

handle_quote:
    // Check if quote is escaped
    TESTQ DX, DX
    JNZ skip_quote

    MOVQ AX, ret+24(FP)      // Return current position
    RET

skip_quote:
    XORQ DX, DX              // Clear escaped state
    INCQ SI
    INCQ AX
    DECQ CX
    JMP small_chunk

not_found:
    MOVQ $-1, ret+24(FP)
    RET

return:
    MOVQ AX, ret+24(FP)
    RET
