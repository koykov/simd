#include "textflag.h"

// func skiplineSSE2(b []byte) int
// Requires: len(b) % 64 == 0 (64-byte aligned)
TEXT ·skiplineSSE2(SB),NOSPLIT,$0-32
    MOVQ b_base+0(FP), SI     // SI = pointer to slice data
    MOVQ b_len+8(FP), CX      // CX = length of slice (must be multiple of 64)
    XORQ AX, AX               // AX will hold result
    DECQ AX                   // Default result = -1

    TESTQ CX, CX
    JZ done                  // Empty slice case

    MOVQ SI, DI              // DI = current pointer
    MOVQ CX, DX              // DX = remaining bytes

    // Prepare X0 = \n\n\n\n... (16 bytes of 0x0A)
    MOVQ $0x0A0A0A0A0A0A0A0A, AX
    MOVQ AX, X0
    PUNPCKLBW X0, X0
    PUNPCKLBW X0, X0

    // Prepare X1 = \r\r\r\r... (16 bytes of 0x0D)
    MOVQ $0x0D0D0D0D0D0D0D0D, AX
    MOVQ AX, X1
    PUNPCKLBW X1, X1
    PUNPCKLBW X1, X1

sse2_loop:
    // Process 64 bytes per iteration (4x16)
    MOVOU (DI), X2         // Load first 16 bytes
    MOVOU 16(DI), X3       // Load second 16 bytes
    MOVOU 32(DI), X4       // Load third 16 bytes
    MOVOU 48(DI), X5       // Load fourth 16 bytes

    // Compare all 4 blocks with \n and \r in parallel
    MOVO X2, X6
    MOVO X3, X7
    MOVO X4, X8
    MOVO X5, X9

    PCMPEQB X0, X2        // Compare first block with \n
    PCMPEQB X0, X3        // Compare second block with \n
    PCMPEQB X0, X4        // Compare third block with \n
    PCMPEQB X0, X5        // Compare fourth block with \n

    PCMPEQB X1, X6        // Compare first block with \r
    PCMPEQB X1, X7        // Compare second block with \r
    PCMPEQB X1, X8        // Compare third block with \r
    PCMPEQB X1, X9        // Compare fourth block with \r

    POR X2, X6            // Combine results for first block
    POR X3, X7            // Combine results for second block
    POR X4, X8            // Combine results for third block
    POR X5, X9            // Combine results for fourth block

    // Check each block for matches
    PMOVMSKB X6, R8       // Get bitmask for first block
    TESTL R8, R8
    JNZ found_first_block

    PMOVMSKB X7, R9       // Get bitmask for second block
    TESTL R9, R9
    JNZ found_second_block

    PMOVMSKB X8, R10      // Get bitmask for third block
    TESTL R10, R10
    JNZ found_third_block

    PMOVMSKB X9, R11      // Get bitmask for fourth block
    TESTL R11, R11
    JNZ found_fourth_block

    ADDQ $64, DI          // Move pointer
    SUBQ $64, DX          // Decrement remaining count
    JNZ sse2_loop         // Continue if bytes remain

notfound:
    XORQ AX, AX
    DECQ AX               // AX = -1
    JMP done

found_first_block:
    BSFQ R8, R8           // Find position in first block
    JMP calc_pos

found_second_block:
    BSFQ R9, R8           // Find position in second block
    ADDQ $16, R8          // Add offset of second block
    JMP calc_pos

found_third_block:
    BSFQ R10, R8          // Find position in third block
    ADDQ $32, R8          // Add offset of third block
    JMP calc_pos

found_fourth_block:
    BSFQ R11, R8          // Find position in fourth block
    ADDQ $48, R8          // Add offset of fourth block

calc_pos:
    MOVQ DI, AX           // AX = current block address
    SUBQ SI, AX           // AX = block offset from start
    ADDQ R8, AX           // AX = total offset (block offset + in-block pos)

done:
    MOVQ AX, ret+24(FP)   // Store result
    RET

// func skiplineAVX2(b []byte) int
// Requires: len(b) % 64 == 0 (64-byte aligned)
TEXT ·skiplineAVX2(SB),NOSPLIT,$0-32
    MOVQ b_base+0(FP), SI     // SI = pointer to slice data
    MOVQ b_len+8(FP), CX      // CX = length of slice (must be multiple of 64)
    XORQ AX, AX               // AX will hold result
    DECQ AX                   // Default result = -1

    TESTQ CX, CX
    JZ done                  // Empty slice case

    MOVQ SI, DI              // DI = current pointer
    MOVQ CX, DX              // DX = remaining bytes

    // Prepare Y0 = \n\n\n\n... (32 bytes of 0x0A)
    MOVQ $0x0A0A0A0A0A0A0A0A, AX
    MOVQ AX, X0
    VPUNPCKLBW X0, X0, X0
    VPUNPCKLBW X0, X0, X0
    VINSERTI128 $1, X0, Y0, Y0

    // Prepare Y1 = \r\r\r\r... (32 bytes of 0x0D)
    MOVQ $0x0D0D0D0D0D0D0D0D, AX
    MOVQ AX, X1
    VPUNPCKLBW X1, X1, X1
    VPUNPCKLBW X1, X1, X1
    VINSERTI128 $1, X1, Y1, Y1

avx2_loop:
    // Process 64 bytes per iteration (2x32)
    VMOVDQU (DI), Y2         // Load first 32 bytes
    VMOVDQU 32(DI), Y4       // Load next 32 bytes

    VPCMPEQB Y0, Y2, Y3      // Compare first block with \n
    VPCMPEQB Y1, Y2, Y2      // Compare first block with \r
    VPOR Y2, Y3, Y3          // Combine results

    VPCMPEQB Y0, Y4, Y5      // Compare second block with \n
    VPCMPEQB Y1, Y4, Y4      // Compare second block with \r
    VPOR Y4, Y5, Y5          // Combine results

    VPMOVMSKB Y3, R8         // Get bitmask for first block
    VPMOVMSKB Y5, R9         // Get bitmask for second block

    TESTL R8, R8
    JNZ found_first_block
    TESTL R9, R9
    JNZ found_second_block

    ADDQ $64, DI             // Move pointer
    SUBQ $64, DX             // Decrement remaining count
    JNZ avx2_loop            // Continue if bytes remain

notfound:
    XORQ AX, AX
    DECQ AX                  // AX = -1
    JMP done

found_first_block:
    BSFQ R8, R8              // Find position in first block
    JMP calc_pos

found_second_block:
    BSFQ R9, R8              // Find position in second block
    ADDQ $32, R8             // Add offset of second block

calc_pos:
    MOVQ DI, AX              // AX = current block address
    SUBQ SI, AX              // AX = block offset from start
    ADDQ R8, AX              // AX = total offset (block offset + in-block pos)

done:
    VZEROUPPER               // Clear upper bits
    MOVQ AX, ret+24(FP)      // Store result
    RET

// func skiplineAVX512(b []byte) int
// Requires: len(b) % 64 == 0 (64-byte aligned)
TEXT ·skiplineAVX512(SB),NOSPLIT,$0-32
    MOVQ b_base+0(FP), SI     // SI = pointer to slice data (constant)
    MOVQ b_len+8(FP), CX      // CX = length of slice (must be multiple of 64)
    XORQ AX, AX               // AX will hold result
    DECQ AX                   // Default result = -1

    TESTQ CX, CX
    JZ done                  // Empty slice case

    MOVQ SI, DI              // DI = current pointer
    MOVQ CX, DX              // DX = remaining bytes (multiple of 64)

    // Prepare constants for comparison using AVX512BW
    MOVQ $0x0A0A0A0A0A0A0A0A, AX
    VPTERNLOGD $0xFF, Z0, Z0, Z0  // Fill Z0 with all 1s
    VPBROADCASTQ AX, Z0           // Z0 = 64 bytes of 0x0A (\n)

    MOVQ $0x0D0D0D0D0D0D0D0D, AX
    VPTERNLOGD $0xFF, Z1, Z1, Z1  // Fill Z1 with all 1s
    VPBROADCASTQ AX, Z1           // Z1 = 64 bytes of 0x0D (\r)

avx512_loop:
    VMOVDQU64 (DI), Z2
    VPCMPEQB Z0, Z2, K1      // Compare with \n
    VPCMPEQB Z1, Z2, K2      // Compare with \r
    KORQ K1, K2, K3          // Combine results
    KTESTQ K3, K3
    JNZ found_in_block

    ADDQ $64, DI             // Move to next block
    SUBQ $64, DX             // Decrement remaining count
    JNZ avx512_loop          // Continue if bytes remain

notfound:
    XORQ AX, AX
    DECQ AX                  // AX = -1
    JMP done

found_in_block:
    KMOVQ K3, R8             // Get bitmask
    BSFQ R8, R8              // Find first set bit (0-based position in block)
    MOVQ DI, AX              // AX = address of block start
    SUBQ SI, AX              // AX = block offset from start
    ADDQ R8, AX              // AX = total offset from start

done:
    VZEROUPPER               // Clear upper bits
    MOVQ AX, ret+24(FP)      // Store result
    RET
