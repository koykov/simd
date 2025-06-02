#include "textflag.h"

// func indexbyteneSSE2(b []byte, x byte) int
TEXT ·indexbyteneSSE2(SB),NOSPLIT,$0-40
    MOVQ b_base+0(FP), SI     // SI = pointer to bytes
    MOVQ b_len+8(FP), CX      // CX = length of bytes
    MOVB x+24(FP), AL         // AL = byte to search for
    XORQ DX, DX               // DX = index (will be returned)

    // Broadcast AL to all bytes of XMM0
    MOVD AX, X0
    PUNPCKLBW X0, X0
    PUNPCKLBW X0, X0
    PSHUFL $0, X0, X0

search_loop:
    // Compare 16 bytes at a time
    MOVOU (SI)(DX*1), X1
    PCMPEQB X0, X1
    PMOVMSKB X1, BX
    TESTL BX, BX
    JZ not_found_chunk

    // Found potential match
    BSFQ BX, BX
    ADDQ BX, DX               // DX = position of quote

    // Now count backslashes before this position
    XORQ R8, R8               // R8 = backslash count
    MOVQ DX, R9               // R9 = current position
    DECQ R9                   // Start checking from previous byte

count_slashes:
    CMPQ R9, $0
    JL count_done             // Stop if we reached start of slice
    CMPB (SI)(R9*1), $0x5C    // Is it backslash?
    JNE count_done
    INCQ R8                   // Increment backslash count
    DECQ R9                   // Move to previous byte
    JMP count_slashes

count_done:
    // If even number of backslashes - found our quote
    TESTQ $1, R8
    JZ found

    // Odd number - continue search from next byte
    INCQ DX
    CMPQ DX, CX
    JGE not_found
    JMP search_loop

found:
    MOVQ DX, ret+32(FP)
    RET

not_found_chunk:
    ADDQ $16, DX
    CMPQ DX, CX
    JLT search_loop

not_found:
    MOVQ $-1, ret+32(FP)
    RET

// func indexbyteneAVX2(b []byte, x byte) int
TEXT ·indexbyteneAVX2(SB),NOSPLIT,$0-40
    MOVQ b_base+0(FP), SI     // SI = pointer to bytes
    MOVQ b_len+8(FP), CX      // CX = length of bytes
    MOVB x+24(FP), AL         // AL = byte to search for
    XORQ DX, DX               // DX = index (will be returned)

    // Broadcast AL to all bytes of YMM0
    MOVD AX, X0
    VPBROADCASTB X0, Y0       // YMM0 = [AL,AL,...,AL] (32 bytes)

search_loop:
    // Compare 32 bytes at a time
    VMOVDQU (SI)(DX*1), Y1    // Load 32 bytes
    VPCMPEQB Y0, Y1, Y1       // Compare with target byte
    VPMOVMSKB Y1, BX          // Get bitmask of matches
    TESTL BX, BX
    JZ not_found_chunk        // No matches in this chunk

    // Found potential match
    BSFQ BX, BX               // Position of first match in chunk
    ADDQ BX, DX               // DX = absolute position of quote

    // Count backslashes before this position
    XORQ R8, R8               // R8 = backslash count
    MOVQ DX, R9               // R9 = current position
    DECQ R9                   // Start checking from previous byte

count_slashes:
    CMPQ R9, $0
    JL count_done             // Stop if we reached start of slice
    CMPB (SI)(R9*1), $0x5C    // Is it backslash?
    JNE count_done
    INCQ R8                   // Increment backslash count
    DECQ R9                   // Move to previous byte
    JMP count_slashes

count_done:
    // If even number of backslashes - found our quote
    TESTQ $1, R8
    JZ found

    // Odd number - continue search from next byte
    INCQ DX
    CMPQ DX, CX
    JGE not_found
    JMP search_loop

found:
    VZEROUPPER                // Clear upper bits of YMM registers
    MOVQ DX, ret+32(FP)
    RET

not_found_chunk:
    ADDQ $32, DX              // Move to next 32-byte chunk
    CMPQ DX, CX
    JLT search_loop

not_found:
    VZEROUPPER                // Clear upper bits of YMM registers
    MOVQ $-1, ret+32(FP)
    RET
