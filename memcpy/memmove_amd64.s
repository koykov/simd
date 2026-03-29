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

	// Small sizes handling (same as original)
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

	// For larger sizes, use AVX512
	CMPQ	BX, $2048
	JL	avx512_small

	// For very large copies (>2MB), use non-temporal stores
	CMPQ	BX, $0x200000
	JAE	avx512_big_forward

	// Medium size forward copy with AVX512
	JMP	avx512_forward

// AVX512 implementations
avx512_forward:
	// Save tail (last 128 bytes) for unaligned handling
	LEAQ	(SI)(BX*1), CX
	SUBQ	$128, CX		// CX points to start of last 128 bytes
	VMOVDQU64 (CX), Z5
	VMOVDQU64 64(CX), Z6

	// Save head (first 64 bytes) for unaligned handling
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

	// Main aligned copy loop - 256 bytes per iteration (4x ZMM)
	MOVQ	BX, R12
	SHRQ	$8, R12		// number of 256-byte blocks
	ANDQ	$255, BX	// remaining bytes after 256-byte blocks

	TESTQ	R12, R12
	JZ	avx512_forward_128_loop_entry

avx512_forward_256_loop:
	// Copy 256 bytes (4x64) using AVX512
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
	DECQ	R12
	JNZ	avx512_forward_256_loop

avx512_forward_128_loop_entry:
	// Handle remaining 128-byte blocks
	MOVQ	BX, R12
	SHRQ	$7, R12		// number of 128-byte blocks
	ANDQ	$127, BX	// remaining bytes

	TESTQ	R12, R12
	JZ	avx512_forward_64_loop_entry

avx512_forward_128_loop:
	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1

	VMOVDQA64 Z0, (DI)
	VMOVDQA64 Z1, 64(DI)

	ADDQ	$128, SI
	ADDQ	$128, DI
	DECQ	R12
	JNZ	avx512_forward_128_loop

avx512_forward_64_loop_entry:
	// Handle remaining 64-byte blocks
	MOVQ	BX, R12
	SHRQ	$6, R12		// number of 64-byte blocks
	ANDQ	$63, BX		// remaining bytes

	TESTQ	R12, R12
	JZ	avx512_forward_restore

avx512_forward_64_loop:
	VMOVDQU64 (SI), Z0
	VMOVDQA64 Z0, (DI)

	ADDQ	$64, SI
	ADDQ	$64, DI
	DECQ	R12
	JNZ	avx512_forward_64_loop

avx512_forward_restore:
	// Restore unaligned parts
	// Calculate the end position for tail restoration
	LEAQ	(DI)(BX*1), CX

	// Restore head
	VMOVDQU64 Z4, (R10)

	// Restore tail (128 bytes) at the end
	SUBQ	$128, CX
	VMOVDQU64 Z5, (CX)
	VMOVDQU64 Z6, 64(CX)

	VZEROUPPER
	RET

avx512_small:
	// For 256-2048 bytes, use simpler approach with AVX512
	LEAQ	(SI)(BX*1), CX
	SUBQ	$128, CX		// CX points to start of last 128 bytes

	// Load tail (last 128 bytes)
	VMOVDQU64 (CX), Z5
	VMOVDQU64 64(CX), Z6

	// Load head
	VMOVDQU64 (SI), Z4

	// Align destination
	MOVQ	DI, R10
	ANDQ	$-64, DI
	ADDQ	$64, DI
	MOVQ	DI, R11
	SUBQ	R10, R11

	SUBQ	R11, BX
	ADDQ	R11, SI

	// Copy aligned blocks
	MOVQ	BX, R12
	SHRQ	$6, R12		// number of 64-byte blocks
	ANDQ	$63, BX

	TESTQ	R12, R12
	JZ	avx512_small_restore

avx512_small_loop:
	VMOVDQU64 (SI), Z0
	VMOVDQA64 Z0, (DI)
	ADDQ	$64, SI
	ADDQ	$64, DI
	DECQ	R12
	JNZ	avx512_small_loop

avx512_small_restore:
	// Restore head and tail
	LEAQ	(DI)(BX*1), CX
	VMOVDQU64 Z4, (R10)
	SUBQ	$128, CX
	VMOVDQU64 Z5, (CX)
	VMOVDQU64 Z6, 64(CX)

	VZEROUPPER
	RET

avx512_big_forward:
	// Large copy with non-temporal stores (>2MB)
	LEAQ	(SI)(BX*1), CX
	SUBQ	$128, CX		// CX points to start of last 128 bytes

	// Save tail
	VMOVDQU64 (CX), Z5
	VMOVDQU64 64(CX), Z6

	// Save head
	VMOVDQU64 (SI), Z4

	// Align destination
	MOVQ	DI, R8
	ANDQ	$-64, DI
	ADDQ	$64, DI
	MOVQ	DI, R10
	SUBQ	R8, R10

	SUBQ	R10, BX
	ADDQ	R10, SI

	// Calculate number of 64-byte blocks
	MOVQ	BX, R12
	SHRQ	$6, R12		// number of 64-byte blocks
	ANDQ	$63, BX		// remaining bytes

	// Prefetch and copy using non-temporal stores
	TESTQ	R12, R12
	JZ	avx512_big_restore

avx512_big_loop:
	// Prefetch ahead (512 bytes ahead)
	PREFETCHNTA 0x200(SI)
	PREFETCHNTA 0x240(SI)
	PREFETCHNTA 0x280(SI)
	PREFETCHNTA 0x2C0(SI)

	// Copy 256 bytes per iteration using non-temporal stores
	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1
	VMOVDQU64 128(SI), Z2
	VMOVDQU64 192(SI), Z3

	VMOVNTDQ Z0, (DI)
	VMOVNTDQ Z1, 64(DI)
	VMOVNTDQ Z2, 128(DI)
	VMOVNTDQ Z3, 192(DI)

	ADDQ	$256, SI
	ADDQ	$256, DI
	SUBQ	$32, R12	// 256 bytes = 4*64, so decrement by 4 blocks
	JA	avx512_big_loop

	// Handle remaining 64-byte blocks
	MOVQ	R12, CX
	ANDQ	$3, CX		// remaining blocks (0-3)
	SHLQ	$6, CX		// convert to bytes

	TESTQ	CX, CX
	JZ	avx512_big_restore

avx512_big_remainder:
	VMOVDQU64 (SI), Z0
	VMOVNTDQ Z0, (DI)
	ADDQ	$64, SI
	ADDQ	$64, DI
	SUBQ	$64, CX
	JNZ	avx512_big_remainder

avx512_big_restore:
	// SFENCE for non-temporal stores
	SFENCE

	// Restore head and tail
	LEAQ	(DI)(BX*1), CX
	VMOVDQU64 Z4, (R8)
	SUBQ	$128, CX
	VMOVDQU64 Z5, (CX)
	VMOVDQU64 Z6, 64(CX)

	VZEROUPPER
	RET

// Small size handlers
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
	VZEROUPPER
	RET
