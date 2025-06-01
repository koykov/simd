#include "textflag.h"

// func indexbyteneSSE2(b []byte, x byte) int
TEXT ·indexbyteneSSE2(SB),NOSPLIT,$0-40
    MOVQ b_base+0(FP), SI     // SI = pointer to bytes
    MOVQ b_len+8(FP), CX      // CX = length of bytes
    MOVB x+24(FP), AL         // AL = byte to search for
    XORQ DX, DX               // DX = index (will be returned)
    XORQ R8, R8               // R8 = backslash count (0 or 1) from previous chunk

    // Broadcast AL to all bytes of XMM0 (target byte)
    MOVD AX, X0
    PUNPCKLBW X0, X0
    PUNPCKLBW X0, X0
    PSHUFL $0, X0, X0

    // Broadcast backslash (0x5C) to all bytes of XMM2
    MOVL $0x5C5C5C5C, BX
    MOVD BX, X2
    PSHUFL $0, X2, X2

loop:
    // Load 16 bytes
    MOVOU (SI)(DX*1), X1      // X1 = current 16 bytes

    // Find target bytes
    PCMPEQB X0, X1            // Compare with target byte
    PMOVMSKB X1, BX           // BX = mask of target bytes

    // Find backslashes
    MOVOU (SI)(DX*1), X3      // Reload bytes
    PCMPEQB X2, X3            // Compare with backslash
    PMOVMSKB X3, DI           // DI = mask of backslashes

    // Process any target bytes found
    TESTL BX, BX
    JZ next_chunk             // No targets in this chunk

check_matches:
    BSFL BX, R9               // Position of first target byte in chunk
    MOVL R9, R10              // Save position

    // Calculate number of preceding backslashes
    MOVQ DI, R11              // Backslash mask
    MOVQ $1, R12
    SHLQ R9, R12              // Mask for all bits before target
    SUBQ $1, R12              // Now R12 has bits set for all positions before target
    ANDQ R11, R12             // Backslashes before target
    POPCNTQ R12, R13          // Count of backslashes before target

    // If previous chunk ended with backslash, and target is first byte
    CMPQ R9, $0
    JNE not_first_byte
    ADDQ R8, R13              // Add backslash from previous chunk

not_first_byte:
    // Target is escaped if odd number of backslashes before it
    TESTQ $1, R13
    JNZ escaped

    // Found unescaped target
    ADDQ R10, DX
    MOVQ DX, ret+32(FP)
    RET

escaped:
    // Clear this target from mask and continue
    BTRQ R9, BX
    JNZ check_matches         // Check next target if any

next_chunk:
    // Check if last byte in chunk is backslash for next iteration
    PEXTRB $15, X3, R9        // Get last byte (backslash comparison)
    ANDL $0xFF, R9
    CMPB R9, $0x5C            // Is it backslash?
    SETEQ R8                  // R8 = 1 if ended with backslash, else 0

    ADDQ $16, DX              // Advance index
    CMPQ DX, CX               // Check bounds
    JB loop                   // Continue if more data

not_found:
    MOVQ $-1, ret+32(FP)      // Return -1 if not found
    RET
