#include "textflag.h"

// func indexbyteSSE2(b []byte, x byte) int
TEXT ·indexbyteSSE2(SB),NOSPLIT,$0-40
    MOVQ b_base+0(FP), SI     // SI = pointer to bytes
    MOVQ b_len+8(FP), CX      // CX = length of bytes
    MOVB x+24(FP), AL         // AL = byte to search for
    XORQ DX, DX               // DX = index (will be returned)

    // Broadcast AL to all bytes of XMM0
    MOVD AX, X0               // Move AL to XMM0
    PUNPCKLBW X0, X0          // Unpack and interleave
    PUNPCKLBW X0, X0          // to fill all bytes
    PSHUFL $0, X0, X0         // Shuffle to all positions

loop:
    // Compare 16 bytes at a time
    MOVOU (SI)(DX*1), X1      // Load 16 bytes
    PCMPEQB X0, X1            // Compare with target byte
    PMOVMSKB X1, BX           // Move byte mask to BX
    TESTL BX, BX              // Check for any matches
    JNZ found                 // If found, jump to found

    ADDQ $16, DX              // Advance index by 16
    CMPQ DX, CX               // Check if we've processed all bytes
    JB loop            // If not, continue loop

not_found:
    MOVQ $-1, ret+32(FP)      // Return -1 if not found
    RET

found:
    // Find the position of the first set bit in BX
    BSFL BX, BX               // Find first set bit
    ADDQ BX, DX               // Add to current offset
    MOVQ DX, ret+32(FP)       // Return the position
    RET
