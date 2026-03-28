//go:build !plan9

#include "go_asm.h"
#include "textflag.h"

// func memmoveAVX512(to, from unsafe.Pointer, n uintptr)
TEXT ·memmoveAVX512(SB), NOSPLIT, $0-24
	MOVQ	to+0(FP), DI
	MOVQ	from+8(FP), SI
	MOVQ	n+16(FP), BX

	TESTQ	BX, BX
	JEQ	move_0

	// Small sizes handling
	CMPQ	BX, $2
	JBE	move_1or2
	CMPQ	BX, $4
	JB	move_3
	JBE	move_4
	CMPQ	BX, $8
	JB	move_5through7
	JE	move_8
	CMPQ	BX, $16
	JBE	move_9through16
	CMPQ	BX, $32
	JBE	move_17through32
	CMPQ	BX, $64
	JBE	move_33through64
	CMPQ	BX, $128
	JBE	move_65through128
	CMPQ	BX, $256
	JBE	move_129through256

	// For larger sizes use AVX512
	JMP	avx512_forward

// AVX512 implementation for forward copy
avx512_forward:
	// Save original destination for head restoration
	MOVQ	DI, R8

	// Calculate end pointer
	LEAQ	(SI)(BX*1), CX

	// Save tail (last 128 bytes) - using negative offsets from end
	VMOVDQU64 -0x80(CX), Z5
	VMOVDQU64 -0x70(CX), Z6
	VMOVDQU64 -0x60(CX), Z7
	VMOVDQU64 -0x50(CX), Z8
	VMOVDQU64 -0x40(CX), Z9
	VMOVDQU64 -0x30(CX), Z10
	VMOVDQU64 -0x20(CX), Z11
	VMOVDQU64 -0x10(CX), Z12

	// Save head (first 64 bytes)
	VMOVDQU64 (SI), Z4

	// Align destination to 64-byte boundary
	MOVQ	DI, R10
	ANDQ	$-64, DI
	ADDQ	$64, DI

	// Calculate adjustment
	MOVQ	DI, R11
	SUBQ	R10, R11

	// Adjust size and source pointer
	SUBQ	R11, BX
	ADDQ	R11, SI

	// Calculate new end pointer for tail restoration
	LEAQ	(DI)(BX*1), CX

	// Main aligned copy loop - process in 256-byte chunks
	MOVQ	BX, AX
	SHRQ	$8, AX		// number of 256-byte blocks
	ANDQ	$0xFF, BX	// remaining bytes after 256-byte blocks

	TESTQ	AX, AX
	JZ	avx512_forward_128

avx512_forward_256_loop:
	// Copy 256 bytes using AVX512
	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1
	VMOVDQU64 128(SI), Z2
	VMOVDQU64 192(SI), Z3

	VMOVDQA64 Z0, (DI)
	VMOVDQA64 Z1, 64(DI)
	VMOVDQA64 Z2, 128(DI)
	VMOVDQA64 Z3, 192(DI)

	ADDQ	$256, SI
	ADDQ	$256, DI
	DECQ	AX
	JNZ	avx512_forward_256_loop

avx512_forward_128:
	// Handle remaining 128-byte blocks
	MOVQ	BX, AX
	SHRQ	$7, AX		// number of 128-byte blocks
	ANDQ	$0x7F, BX	// remaining bytes

	TESTQ	AX, AX
	JZ	avx512_forward_64

avx512_forward_128_loop:
	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1

	VMOVDQA64 Z0, (DI)
	VMOVDQA64 Z1, 64(DI)

	ADDQ	$128, SI
	ADDQ	$128, DI
	DECQ	AX
	JNZ	avx512_forward_128_loop

avx512_forward_64:
	// Handle remaining 64-byte blocks
	MOVQ	BX, AX
	SHRQ	$6, AX		// number of 64-byte blocks
	ANDQ	$0x3F, BX	// remaining bytes

	TESTQ	AX, AX
	JZ	avx512_forward_restore_head

avx512_forward_64_loop:
	VMOVDQU64 (SI), Z0
	VMOVDQA64 Z0, (DI)

	ADDQ	$64, SI
	ADDQ	$64, DI
	DECQ	AX
	JNZ	avx512_forward_64_loop

avx512_forward_restore_head:
	// Restore head at original destination
	VMOVDQU64 Z4, (R8)

	// Restore tail at the end
	// Calculate tail destination
	LEAQ	(R8)(BX*1), R9
	ADDQ	R11, R9

	VMOVDQU64 Z5, -0x80(R9)
	VMOVDQU64 Z6, -0x70(R9)
	VMOVDQU64 Z7, -0x60(R9)
	VMOVDQU64 Z8, -0x50(R9)
	VMOVDQU64 Z9, -0x40(R9)
	VMOVDQU64 Z10, -0x30(R9)
	VMOVDQU64 Z11, -0x20(R9)
	VMOVDQU64 Z12, -0x10(R9)

	VZEROUPPER
	RET

// Small size handlers (optimized with AVX512 for larger small sizes)
move_1or2:
	MOVB	(SI), AX
	MOVB	-1(SI)(BX*1), CX
	MOVB	AX, (DI)
	MOVB	CX, -1(DI)(BX*1)
	RET

move_0:
	RET

move_4:
	MOVL	(SI), AX
	MOVL	AX, (DI)
	RET

move_3:
	MOVW	(SI), AX
	MOVB	2(SI), CX
	MOVW	AX, (DI)
	MOVB	CX, 2(DI)
	RET

move_5through7:
	MOVL	(SI), AX
	MOVL	-4(SI)(BX*1), CX
	MOVL	AX, (DI)
	MOVL	CX, -4(DI)(BX*1)
	RET

move_8:
	MOVQ	(SI), AX
	MOVQ	AX, (DI)
	RET

move_9through16:
	MOVQ	(SI), AX
	MOVQ	-8(SI)(BX*1), CX
	MOVQ	AX, (DI)
	MOVQ	CX, -8(DI)(BX*1)
	RET

move_17through32:
	VMOVDQU64 (SI), Z0
	VMOVDQU64 -32(SI)(BX*1), Z1
	VMOVDQU64 Z0, (DI)
	VMOVDQU64 Z1, -32(DI)(BX*1)
	VZEROUPPER
	RET

move_33through64:
	VMOVDQU64 (SI), Z0
	VMOVDQU64 32(SI), Z1
	VMOVDQU64 -64(SI)(BX*1), Z2
	VMOVDQU64 -32(SI)(BX*1), Z3
	VMOVDQU64 Z0, (DI)
	VMOVDQU64 Z1, 32(DI)
	VMOVDQU64 Z2, -64(DI)(BX*1)
	VMOVDQU64 Z3, -32(DI)(BX*1)
	VZEROUPPER
	RET

move_65through128:
	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1
	VMOVDQU64 -128(SI)(BX*1), Z2
	VMOVDQU64 -64(SI)(BX*1), Z3
	VMOVDQU64 Z0, (DI)
	VMOVDQU64 Z1, 64(DI)
	VMOVDQU64 Z2, -128(DI)(BX*1)
	VMOVDQU64 Z3, -64(DI)(BX*1)
	VZEROUPPER
	RET

move_129through256:
	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1
	VMOVDQU64 128(SI), Z2
	VMOVDQU64 192(SI), Z3
	VMOVDQU64 -256(SI)(BX*1), Z4
	VMOVDQU64 -192(SI)(BX*1), Z5
	VMOVDQU64 -128(SI)(BX*1), Z6
	VMOVDQU64 -64(SI)(BX*1), Z7
	VMOVDQU64 Z0, (DI)
	VMOVDQU64 Z1, 64(DI)
	VMOVDQU64 Z2, 128(DI)
	VMOVDQU64 Z3, 192(DI)
	VMOVDQU64 Z4, -256(DI)(BX*1)
	VMOVDQU64 Z5, -192(DI)(BX*1)
	VMOVDQU64 Z6, -128(DI)(BX*1)
	VMOVDQU64 Z7, -64(DI)(BX*1)
	// Clear upper registers
	VZEROUPPER
	RET
