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

// func indexbyteAVX2(b []byte, x byte) int
TEXT ·indexbyteAVX2(SB),NOSPLIT,$0-40
    MOVQ b_base+0(FP), SI     // SI = pointer to bytes
    MOVQ b_len+8(FP), CX      // CX = length of bytes
    MOVB x+24(FP), AL         // AL = byte to search for
    XORQ DX, DX               // DX = index (will be returned)

    // Broadcast AL to all bytes of YMM0
    MOVD AX, X0               // Move AL to XMM0
    VPBROADCASTB X0, Y0       // Broadcast byte to all 32 bytes of YMM0

loop:
    // Compare 32 bytes at a time
    VMOVDQU (SI)(DX*1), Y1    // Load 32 bytes
    VPCMPEQB Y0, Y1, Y1       // Compare with target byte
    VPMOVMSKB Y1, BX          // Move byte mask to BX
    TESTL BX, BX              // Check for any matches
    JNZ found                 // If found, jump to found

    ADDQ $32, DX              // Advance index by 32
    CMPQ DX, CX               // Check if we've processed all bytes
    JB loop                   // If not, continue loop

not_found:
    VZEROUPPER                // Clear upper bits of YMM registers
    MOVQ $-1, ret+32(FP)      // Return -1 if not found
    RET

found:
    // Find the position of the first set bit in BX
    BSFL BX, BX               // Find first set bit
    ADDQ BX, DX               // Add to current offset
    VZEROUPPER                // Clear upper bits of YMM registers
    MOVQ DX, ret+32(FP)       // Return the position
    RET

// func indexbyteAVX512(b []byte, x byte) int
TEXT ·indexbyteAVX512(SB),NOSPLIT,$0-40
    MOVQ b_base+0(FP), SI     // SI = pointer to bytes
    MOVQ b_len+8(FP), CX      // CX = length of bytes
    MOVB x+24(FP), AL         // AL = byte to search for
    XORQ DX, DX               // DX = index (will be returned)

    // Broadcast AL to all 64 bytes of ZMM0
    MOVD AX, X0               // Move AL to XMM0
    VPBROADCASTB X0, Z0       // Broadcast to all 64 bytes of ZMM0 (AVX512VL + AVX512BW)

loop:
    // Compare 64 bytes at a time
    VMOVDQU8 (SI)(DX*1), Z1   // Load 64 bytes (AVX512F)
    VPCMPEQB k1, Z0, Z1       // Compare bytes, mask result in k1 (AVX512BW)
    KTESTQ k1, k1             // Check if any bits set in mask k1
    JNZ found                 // If found, jump to found

    ADDQ $64, DX              // Advance index by 64
    CMPQ DX, CX               // Check if we've processed all bytes
    JB loop                   // If not, continue loop

not_found:
    VZEROUPPER                // Clear upper bits of ZMM/YMM registers
    MOVQ $-1, ret+32(FP)      // Return -1 if not found
    RET

found:
    // Find the position of the first set bit in k1
    KMOVQ k1, BX              // Move mask to general-purpose register
    BSFQ BX, BX               // Find first set bit (Bit Scan Forward)
    ADDQ BX, DX               // Add to current offset
    VZEROUPPER                // Clear upper bits
    MOVQ DX, ret+32(FP)       // Return the position
    RET
