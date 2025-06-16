#include "textflag.h"

// func eoqsSSE2(b []byte) int
TEXT ·eoqsSSE2(SB),NOSPLIT,$0-28
    MOVQ b_base+0(FP), SI     // SI = pointer to byte slice data
    MOVQ b_len+8(FP), CX      // CX = length of byte slice
    XORQ AX, AX               // AX = current position (will be result)

    // Preload constants
    MOVQ $0x2222222222222222, BX  // BX = 8x quote (")
    MOVQ BX, X7
    PUNPCKLBW X7, X7
    PUNPCKLBW X7, X7           // X7 = 16x quote (")

    MOVQ $0x5C5C5C5C5C5C5C5C, BX  // BX = 8x backslash (\)
    MOVQ BX, X6
    PUNPCKLBW X6, X6
    PUNPCKLBW X6, X6           // X6 = 16x backslash (\)

    XORQ DX, DX               // DX = escaped state (0 = not escaped)

loop64:
    CMPQ CX, $64
    JB loop16
    MOVOU (SI), X0            // Load 16 bytes
    MOVOU 16(SI), X1
    MOVOU 32(SI), X2
    MOVOU 48(SI), X3

    // Compare with quotes
    MOVOU X0, X4
    PCMPEQB X7, X4
    PMOVMSKB X4, BX
    MOVOU X1, X4
    PCMPEQB X7, X4
    PMOVMSKB X4, BP
    MOVOU X2, X4
    PCMPEQB X7, X4
    PMOVMSKB X4, DI
    MOVOU X3, X4
    PCMPEQB X7, X4
    PMOVMSKB X4, R8

    // Compare with backslashes
    MOVOU X0, X4
    PCMPEQB X6, X4
    PMOVMSKB X4, R9
    MOVOU X1, X4
    PCMPEQB X6, X4
    PMOVMSKB X4, R10
    MOVOU X2, X4
    PCMPEQB X6, X4
    PMOVMSKB X4, R11
    MOVOU X3, X4
    PCMPEQB X6, X4
    PMOVMSKB X4, R12

    // Process 64 bytes in chunks of 16
    ADDQ $64, SI
    SUBQ $64, CX
    ADDQ $64, AX

    // Check for backslashes first (they affect quote matching)
    ORQ R9, R10
    ORQ R11, R12
    ORQ R10, R12
    JZ check_quotes         // No backslashes in this chunk

    // Process each 16-byte chunk separately
    CALL processChunk, BX, R9, $0
    CALL processChunk, BP, R10, $16
    CALL processChunk, DI, R11, $32
    CALL processChunk, R8, R12, $48

    JMP loop64

check_quotes:
    ORQ BX, BP
    ORQ DI, R8
    ORQ BP, R8
    JZ loop64               // No quotes in this chunk

    // Found quotes - check if any is not escaped
    TESTQ DX, DX
    JNZ check_escaped_quotes

    // Not in escaped state - find first quote
    BSFQ BX, BX
    JNZ found
    BSFQ BP, BP
    JNZ found16
    BSFQ DI, DI
    JNZ found32
    BSFQ R8, R8
    JNZ found48

    JMP loop64

check_escaped_quotes:
    // In escaped state - need to check if quote is escaped
    // This is more complex, we'll handle it in the processChunk
    JMP loop64

found:
    LEAQ -64(AX)(BX*1), AX
    JMP return
found16:
    LEAQ -48(AX)(BP*1), AX
    JMP return
found32:
    LEAQ -32(AX)(DI*1), AX
    JMP return
found48:
    LEAQ -16(AX)(R8*1), AX

return:
    MOVQ AX, ret+24(FP)
    RET

processChunk:
    // Args: quote mask, backslash mask, offset
    // Modifies: DX (escape state), may find result
    PUSHQ BP
    MOVQ SP, BP

    MOVQ 16(BP), BX        // quote mask
    MOVQ 24(BP), R9        // backslash mask
    MOVQ 32(BP), R10       // offset

    TESTQ R9, R9
    JZ check_quotes_chunk

    // Process backslashes first
    XORQ R11, R11          // bit position

backslash_loop:
    BSFQ R9, R12           // find next backslash
    JZ backslash_done

    // Check if this backslash escapes a quote
    MOVQ $1, R13
    SHLQ R12, R13
    SHLQ $1, R13           // look at next bit (quote)
    ANDQ BX, R13
    JZ not_escaping_quote

    // This backslash escapes a quote - mark it
    BTRQ R12, R9           // clear backslash bit
    BTRQ R12, BX           // clear quote bit
    BTSQ R12, R11          // mark as escaped quote

not_escaping_quote:
    BTRQ R12, R9           // clear current backslash bit
    JMP backslash_loop

backslash_done:
    // Now check quotes
    TESTQ BX, BX
    JZ chunk_done

    // Check if we're in escaped state
    TESTQ DX, DX
    JNZ escaped_state

    // Not in escaped state - find first unescaped quote
    BSFQ BX, BX
    LEAQ (R10)(BX*1), AX
    SUBQ $64, AX           // adjust for current chunk
    JMP found_return

escaped_state:
    // In escaped state - quotes are only valid if not preceded by backslash
    // We've already processed that with R11
    BSFQ BX, BX
    MOVQ $1, R12
    SHLQ BX, R12
    BTQ BX, R11            // check if this quote was escaped
    JC next_quote

    // Found unescaped quote
    LEAQ (R10)(BX*1), AX
    SUBQ $64, AX           // adjust for current chunk
    JMP found_return

next_quote:
    BTRQ BX, BX
    JMP escaped_state

check_quotes_chunk:
    TESTQ BX, BX
    JZ chunk_done

    BSFQ BX, BX
    LEAQ (R10)(BX*1), AX
    SUBQ $64, AX           // adjust for current chunk

found_return:
    MOVQ AX, ret+24(FP)    // return found position
    MOVQ BP, SP
    POPQ BP
    RET

chunk_done:
    // Update escaped state (if last char is backslash)
    MOVQ R9, DX
    POPQ BP
    RET

loop16:
    CMPQ CX, $16
    JB small_chunk
    MOVOU (SI), X0

    // Compare with quotes
    MOVOU X0, X4
    PCMPEQB X7, X4
    PMOVMSKB X4, BX

    // Compare with backslashes
    MOVOU X0, X4
    PCMPEQB X6, X4
    PMOVMSKB X4, R9

    ADDQ $16, SI
    SUBQ $16, CX
    ADDQ $16, AX

    CALL processChunk, BX, R9, $0
    JMP loop16

small_chunk:
    TESTQ CX, CX
    JZ not_found

    MOVB (SI), BL
    CMPB BL, $0x5C          // backslash
    JE handle_backslash_small
    CMPB BL, $0x22          // quote
    JE handle_quote_small

    INCQ SI
    INCQ AX
    DECQ CX
    JMP small_chunk

handle_backslash_small:
    // Skip next character if it exists
    ADDQ $2, SI
    ADDQ $2, AX
    SUBQ $2, CX
    JNS small_chunk
    JMP not_found

handle_quote_small:
    // Check if quote is escaped
    CMPQ DX, $0
    JNE not_found            // in escaped state

    DECQ AX                 // adjust position
    MOVQ AX, ret+24(FP)
    RET

not_found:
    MOVQ $-1, ret+24(FP)
    RET
