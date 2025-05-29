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
    MOVD AX, X0
    VPBROADCASTB X0, Z0

    // Prepare full mask
    KXNORW K1, K1, K1         // Set all mask bits to 1

    // Adjust length to avoid overflow
    MOVQ CX, BX
    SUBQ $64, BX              // BX = length - 64 (last safe position)

main_loop:
    CMPQ DX, BX               // Compare index with (length-64)
    JA tail_processing        // If above, process tail

    // Process 64-byte blocks
    VMOVDQU8 (SI)(DX*1), Z1
    VPCMPB $0, Z0, Z1, K1     // Compare for equality
    KORTESTW K1, K1
    JNZ found_in_block

    ADDQ $64, DX
    JMP main_loop

tail_processing:
    // Handle last block (or single block if small)
    VMOVDQU8 (SI)(BX*1), Z1   // Load last 64 bytes
    VPCMPB $0, Z0, Z1, K1
    KORTESTW K1, K1
    JNZ found_in_block

not_found:
    VZEROUPPER
    MOVQ $-1, ret+32(FP)
    RET

found_in_block:
    KMOVQ K1, AX
    BSFQ AX, AX
    ADDQ DX, AX               // DX contains base offset
    CMPQ AX, CX               // Verify we're within bounds
    JAE not_found             // If beyond length, return -1
    VZEROUPPER
    MOVQ AX, ret+32(FP)
    RET
