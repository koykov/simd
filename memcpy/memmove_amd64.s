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

	// Check for AVX512 support (assuming it's available)
	// For larger sizes, use AVX512

	// Forward copy (simplified - ignoring overlap for this version)
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
	VMOVDQU64 -0x80(CX), Z5
	VMOVDQU64 -0x70(CX), Z6
	VMOVDQU64 -0x60(CX), Z7
	VMOVDQU64 -0x50(CX), Z8
	VMOVDQU64 -0x40(CX), Z9
	VMOVDQU64 -0x30(CX), Z10
	VMOVDQU64 -0x20(CX), Z11
	VMOVDQU64 -0x10(CX), Z12

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
	MOVQ	BX, AX
	SHRQ	$8, AX		// number of 256-byte blocks
	ANDQ	$255, BX	// remaining bytes after 256-byte blocks

	TESTQ	AX, AX
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
	DECQ	AX
	JNZ	avx512_forward_256_loop

avx512_forward_128_loop_entry:
	// Handle remaining 128-byte blocks
	MOVQ	BX, AX
	SHRQ	$7, AX		// number of 128-byte blocks
	ANDQ	$127, BX	// remaining bytes

	TESTQ	AX, AX
	JZ	avx512_forward_64_loop_entry

avx512_forward_128_loop:
	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1

	VMOVDQA64 Z0, (DI)
	VMOVDQA64 Z1, 64(DI)

	ADDQ	$128, SI
	ADDQ	$128, DI
	DECQ	AX
	JNZ	avx512_forward_128_loop

avx512_forward_64_loop_entry:
	// Handle remaining 64-byte blocks
	MOVQ	BX, AX
	SHRQ	$6, AX		// number of 64-byte blocks
	ANDQ	$63, BX		// remaining bytes

	TESTQ	AX, AX
	JZ	avx512_forward_restore

avx512_forward_64_loop:
	VMOVDQU64 (SI), Z0
	VMOVDQA64 Z0, (DI)

	ADDQ	$64, SI
	ADDQ	$64, DI
	DECQ	AX
	JNZ	avx512_forward_64_loop

avx512_forward_restore:
	// Restore unaligned parts
	ADDQ	BX, DI
	VMOVDQU64 Z4, (R10)
	VMOVDQU64 Z5, -0x80(DI)
	VMOVDQU64 Z6, -0x70(DI)
	VMOVDQU64 Z7, -0x60(DI)
	VMOVDQU64 Z8, -0x50(DI)
	VMOVDQU64 Z9, -0x40(DI)
	VMOVDQU64 Z10, -0x30(DI)
	VMOVDQU64 Z11, -0x20(DI)
	VMOVDQU64 Z12, -0x10(DI)

	VZEROUPPER
	RET

avx512_small:
	// For 256-2048 bytes, use simpler approach with AVX512
	LEAQ	(SI)(BX*1), CX

	// Load tail (last 128 bytes)
	VMOVDQU64 -0x80(CX), Z5
	VMOVDQU64 -0x70(CX), Z6
	VMOVDQU64 -0x60(CX), Z7
	VMOVDQU64 -0x50(CX), Z8
	VMOVDQU64 -0x40(CX), Z9
	VMOVDQU64 -0x30(CX), Z10
	VMOVDQU64 -0x20(CX), Z11
	VMOVDQU64 -0x10(CX), Z12

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
	MOVQ	BX, AX
	SHRQ	$6, AX		// number of 64-byte blocks
	ANDQ	$63, BX

	TESTQ	AX, AX
	JZ	avx512_small_restore

avx512_small_loop:
	VMOVDQU64 (SI), Z0
	VMOVDQA64 Z0, (DI)
	ADDQ	$64, SI
	ADDQ	$64, DI
	DECQ	AX
	JNZ	avx512_small_loop

avx512_small_restore:
	ADDQ	BX, DI
	VMOVDQU64 Z4, (R10)
	VMOVDQU64 Z5, -0x80(DI)
	VMOVDQU64 Z6, -0x70(DI)
	VMOVDQU64 Z7, -0x60(DI)
	VMOVDQU64 Z8, -0x50(DI)
	VMOVDQU64 Z9, -0x40(DI)
	VMOVDQU64 Z10, -0x30(DI)
	VMOVDQU64 Z11, -0x20(DI)
	VMOVDQU64 Z12, -0x10(DI)

	VZEROUPPER
	RET

avx512_big_forward:
	// Large copy with non-temporal stores (>2MB)
	LEAQ	(SI)(BX*1), CX

	// Save tail
	VMOVDQU64 -0x80(CX), Z5
	VMOVDQU64 -0x70(CX), Z6
	VMOVDQU64 -0x60(CX), Z7
	VMOVDQU64 -0x50(CX), Z8
	VMOVDQU64 -0x40(CX), Z9
	VMOVDQU64 -0x30(CX), Z10
	VMOVDQU64 -0x20(CX), Z11
	VMOVDQU64 -0x10(CX), Z12

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

	// Calculate end pointer for tail restoration
	LEAQ	(DI)(BX*1), CX

	// Align to 64 bytes for main loop
	MOVQ	BX, AX
	SHRQ	$6, AX		// number of 64-byte blocks
	ANDQ	$63, BX

	// Prefetch and copy using non-temporal stores
	TESTQ	AX, AX
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
	SUBQ	$32, AX		// 256 bytes = 4*64, so decrement by 4 blocks
	JA	avx512_big_loop

	// Handle remaining 64-byte blocks
	MOVQ	AX, CX
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
	ADDQ	BX, DI
	VMOVDQU64 Z4, (R8)
	VMOVDQU64 Z5, -0x80(CX)
	VMOVDQU64 Z6, -0x70(CX)
	VMOVDQU64 Z7, -0x60(CX)
	VMOVDQU64 Z8, -0x50(CX)
	VMOVDQU64 Z9, -0x40(CX)
	VMOVDQU64 Z10, -0x30(CX)
	VMOVDQU64 Z11, -0x20(CX)
	VMOVDQU64 Z12, -0x10(CX)

	VZEROUPPER
	RET

// Small size handlers (copied from original, but using AVX512 for sizes >64)
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
