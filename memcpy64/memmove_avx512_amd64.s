//go:build !plan9

#include "go_asm.h"
#include "textflag.h"

TEXT ·memmoveAVX512(SB), NOSPLIT, $0-24
	// AX = to
	// BX = from
	// CX = n
	MOVQ	to+0(FP), DI
	MOVQ	from+8(FP), SI
	MOVQ	n+16(FP), BX

tail:
	TESTQ	BX, BX
	JEQ	move_0
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
	CMPQ	BX, $512
	JBE	move_257through512
	CMPQ	BX, $1024
	JBE	move_513through1024
	CMPQ	BX, $2048
	JBE	move_1025through2048

	// Check for overlap and choose direction
	CMPQ	SI, DI
	JLS	back

	// Forward copy with AVX512
forward:
	// For very large copies, use non-temporal stores
	CMPQ	BX, $0x100000
	JAE	gobble_big_data_fwd_avx512

	// Check alignment for optimal path
	MOVQ	DI, AX
	ORQ	SI, AX
	TESTQ	$63, AX
	JEQ	fwd_aligned_avx512

	// Unaligned forward copy with AVX512
	JMP	avx512_forward_unaligned

back:
	// Check if regions overlap
	MOVQ	SI, CX
	ADDQ	BX, CX
	CMPQ	CX, DI
	JLS	forward

	// Backward copy with AVX512
	CMPQ	BX, $0x100000
	JAE	gobble_big_data_bwd_avx512

	JMP	avx512_backward_unaligned

// Small sizes handling (0-256 bytes) - same as original memmove
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
	MOVOU	(SI), X0
	MOVOU	-16(SI)(BX*1), X1
	MOVOU	X0, (DI)
	MOVOU	X1, -16(DI)(BX*1)
	RET
move_33through64:
	MOVOU	(SI), X0
	MOVOU	16(SI), X1
	MOVOU	-32(SI)(BX*1), X2
	MOVOU	-16(SI)(BX*1), X3
	MOVOU	X0, (DI)
	MOVOU	X1, 16(DI)
	MOVOU	X2, -32(DI)(BX*1)
	MOVOU	X3, -16(DI)(BX*1)
	RET
move_65through128:
	MOVOU	(SI), X0
	MOVOU	16(SI), X1
	MOVOU	32(SI), X2
	MOVOU	48(SI), X3
	MOVOU	-64(SI)(BX*1), X4
	MOVOU	-48(SI)(BX*1), X5
	MOVOU	-32(SI)(BX*1), X6
	MOVOU	-16(SI)(BX*1), X7
	MOVOU	X0, (DI)
	MOVOU	X1, 16(DI)
	MOVOU	X2, 32(DI)
	MOVOU	X3, 48(DI)
	MOVOU	X4, -64(DI)(BX*1)
	MOVOU	X5, -48(DI)(BX*1)
	MOVOU	X6, -32(DI)(BX*1)
	MOVOU	X7, -16(DI)(BX*1)
	RET
move_129through256:
	MOVOU	(SI), X0
	MOVOU	16(SI), X1
	MOVOU	32(SI), X2
	MOVOU	48(SI), X3
	MOVOU	64(SI), X4
	MOVOU	80(SI), X5
	MOVOU	96(SI), X6
	MOVOU	112(SI), X7
	MOVOU	-128(SI)(BX*1), X8
	MOVOU	-112(SI)(BX*1), X9
	MOVOU	-96(SI)(BX*1), X10
	MOVOU	-80(SI)(BX*1), X11
	MOVOU	-64(SI)(BX*1), X12
	MOVOU	-48(SI)(BX*1), X13
	MOVOU	-32(SI)(BX*1), X14
	MOVOU	-16(SI)(BX*1), X15
	MOVOU	X0, (DI)
	MOVOU	X1, 16(DI)
	MOVOU	X2, 32(DI)
	MOVOU	X3, 48(DI)
	MOVOU	X4, 64(DI)
	MOVOU	X5, 80(DI)
	MOVOU	X6, 96(DI)
	MOVOU	X7, 112(DI)
	MOVOU	X8, -128(DI)(BX*1)
	MOVOU	X9, -112(DI)(BX*1)
	MOVOU	X10, -96(DI)(BX*1)
	MOVOU	X11, -80(DI)(BX*1)
	MOVOU	X12, -64(DI)(BX*1)
	MOVOU	X13, -48(DI)(BX*1)
	MOVOU	X14, -32(DI)(BX*1)
	MOVOU	X15, -16(DI)(BX*1)
	PXOR	X15, X15
	RET

// New AVX512 handlers for 257-2048 bytes
move_257through512:
	// Copy first and last 256 bytes with AVX512
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

move_513through1024:
	// Copy first and last 512 bytes with AVX512
	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1
	VMOVDQU64 128(SI), Z2
	VMOVDQU64 192(SI), Z3
	VMOVDQU64 256(SI), Z4
	VMOVDQU64 320(SI), Z5
	VMOVDQU64 384(SI), Z6
	VMOVDQU64 448(SI), Z7
	VMOVDQU64 -512(SI)(BX*1), Z8
	VMOVDQU64 -448(SI)(BX*1), Z9
	VMOVDQU64 -384(SI)(BX*1), Z10
	VMOVDQU64 -320(SI)(BX*1), Z11
	VMOVDQU64 -256(SI)(BX*1), Z12
	VMOVDQU64 -192(SI)(BX*1), Z13
	VMOVDQU64 -128(SI)(BX*1), Z14
	VMOVDQU64 -64(SI)(BX*1), Z15

	VMOVDQU64 Z0, (DI)
	VMOVDQU64 Z1, 64(DI)
	VMOVDQU64 Z2, 128(DI)
	VMOVDQU64 Z3, 192(DI)
	VMOVDQU64 Z4, 256(DI)
	VMOVDQU64 Z5, 320(DI)
	VMOVDQU64 Z6, 384(DI)
	VMOVDQU64 Z7, 448(DI)
	VMOVDQU64 Z8, -512(DI)(BX*1)
	VMOVDQU64 Z9, -448(DI)(BX*1)
	VMOVDQU64 Z10, -384(DI)(BX*1)
	VMOVDQU64 Z11, -320(DI)(BX*1)
	VMOVDQU64 Z12, -256(DI)(BX*1)
	VMOVDQU64 Z13, -192(DI)(BX*1)
	VMOVDQU64 Z14, -128(DI)(BX*1)
	VMOVDQU64 Z15, -64(DI)(BX*1)
	VZEROUPPER
	RET

move_1025through2048:
	// Use loop for larger sizes
	MOVQ	BX, R8
	SHRQ	$7, R8		// divide by 128 (2*64 bytes) for loop count
	ANDQ	$127, BX	// remainder

move_1025through2048_loop:
	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1
	VMOVDQU64 Z0, (DI)
	VMOVDQU64 Z1, 64(DI)
	ADDQ	$128, SI
	ADDQ	$128, DI
	DECQ	R8
	JNZ	move_1025through2048_loop

	// Handle remainder
	JMP	tail

// AVX512 forward copy with alignment
fwd_aligned_avx512:
	MOVQ	BX, CX
	SHRQ	$6, CX		// divide by 64
	ANDQ	$63, BX		// remainder

	TESTQ	CX, CX
	JEQ	fwd_aligned_tail

fwd_aligned_loop:
	VMOVDQA64 (SI), Z0
	VMOVDQA64 Z0, (DI)
	ADDQ	$64, SI
	ADDQ	$64, DI
	DECQ	CX
	JNZ	fwd_aligned_loop

fwd_aligned_tail:
	JMP	tail

// AVX512 unaligned forward copy
avx512_forward_unaligned:
	LEAQ	(SI)(BX*1), CX	// end of source
	MOVQ	DI, R8		// save original destination

	// Save tail (last 128 bytes) into Z registers
	VMOVDQU64 -128(CX), Z20
	VMOVDQU64 -64(CX), Z21

	// Align destination to 64-byte boundary
	MOVQ	DI, R9
	ANDQ	$-64, DI
	ADDQ	$64, DI
	MOVQ	DI, R10
	SUBQ	R8, R10		// alignment adjustment

	// Save head (first 64 bytes) from original source
	VMOVDQU64 (SI), Z22

	// Adjust source and size
	ADDQ	R10, SI
	SUBQ	R10, BX
	SUBQ	$128, BX	// reserve for tail

	// Main loop - copy 256 bytes per iteration
	MOVQ	BX, R11
	SHRQ	$8, R11		// divide by 256
	ANDQ	$255, BX	// remainder

	TESTQ	R11, R11
	JEQ	fwd_loop_done

fwd_avx512_loop:
	PREFETCHNTA 256(SI)
	PREFETCHNTA 320(SI)

	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1
	VMOVDQU64 128(SI), Z2
	VMOVDQU64 192(SI), Z3

	VMOVDQU64 Z0, (DI)
	VMOVDQU64 Z1, 64(DI)
	VMOVDQU64 Z2, 128(DI)
	VMOVDQU64 Z3, 192(DI)

	ADDQ	$256, SI
	ADDQ	$256, DI
	DECQ	R11
	JNZ	fwd_avx512_loop

fwd_loop_done:
	// Restore BX to remaining bytes
	ADDQ	$128, BX

	// Handle remaining data with smaller chunks
	CMPQ	BX, $64
	JB	fwd_remaining_less_64

	VMOVDQU64 (SI), Z0
	VMOVDQU64 Z0, (DI)
	ADDQ	$64, SI
	ADDQ	$64, DI
	SUBQ	$64, BX
	JMP	fwd_loop_done

fwd_remaining_less_64:
	// Store head and tail
	VMOVDQU64 Z22, (R8)
	VMOVDQU64 Z20, -128(R8)(BX*1)
	VMOVDQU64 Z21, -64(R8)(BX*1)

	VZEROUPPER
	RET

// AVX512 backward copy for overlapping regions
avx512_backward_unaligned:
	MOVQ	DI, R8		// save original destination start
	ADDQ	BX, DI		// point to end of destination
	ADDQ	BX, SI		// point to end of source

	// Save head (first 128 bytes) from beginning
	VMOVDQU64 -128(R8), Z20
	VMOVDQU64 -64(R8), Z21

	// Align destination end to 64-byte boundary going backwards
	MOVQ	DI, R9
	ANDQ	$-64, DI

	// Save tail (last 64 bytes) from original source end
	VMOVDQU64 -64(SI), Z22

	// Adjust source and size
	MOVQ	DI, R10
	SUBQ	R8, R10
	SUBQ	R10, SI
	SUBQ	R10, BX
	SUBQ	$128, BX	// reserve for head

	// Main backward loop
	MOVQ	BX, R11
	SHRQ	$8, R11		// divide by 256
	ANDQ	$255, BX	// remainder

	TESTQ	R11, R11
	JEQ	bwd_loop_done

bwd_avx512_loop:
	PREFETCHNTA -256(SI)
	PREFETCHNTA -320(SI)

	VMOVDQU64 -64(SI), Z0
	VMOVDQU64 -128(SI), Z1
	VMOVDQU64 -192(SI), Z2
	VMOVDQU64 -256(SI), Z3

	VMOVDQU64 Z0, -64(DI)
	VMOVDQU64 Z1, -128(DI)
	VMOVDQU64 Z2, -192(DI)
	VMOVDQU64 Z3, -256(DI)

	SUBQ	$256, SI
	SUBQ	$256, DI
	DECQ	R11
	JNZ	bwd_avx512_loop

bwd_loop_done:
	ADDQ	$128, BX

	// Handle remaining
	CMPQ	BX, $64
	JB	bwd_remaining_less_64

	SUBQ	$64, SI
	SUBQ	$64, DI
	VMOVDQU64 (SI), Z0
	VMOVDQU64 Z0, (DI)
	SUBQ	$64, BX
	JMP	bwd_loop_done

bwd_remaining_less_64:
	// Store head and tail
	VMOVDQU64 Z22, -64(R8)(BX*1)
	VMOVDQU64 Z20, (R8)
	VMOVDQU64 Z21, 64(R8)

	VZEROUPPER
	RET

// Very large forward copy with non-temporal stores
gobble_big_data_fwd_avx512:
	LEAQ	(SI)(BX*1), CX	// end of source
	MOVQ	DI, R8		// save original destination

	// Save tail (last 256 bytes)
	VMOVDQU64 -256(CX), Z24
	VMOVDQU64 -192(CX), Z25
	VMOVDQU64 -128(CX), Z26
	VMOVDQU64 -64(CX), Z27

	// Align destination
	MOVQ	DI, R9
	ANDQ	$-64, DI
	ADDQ	$64, DI
	MOVQ	DI, R10
	SUBQ	R8, R10

	// Save head
	VMOVDQU64 (SI), Z28
	VMOVDQU64 64(SI), Z29

	// Adjust
	ADDQ	R10, SI
	SUBQ	R10, BX
	SUBQ	$256, BX

	// Main loop with prefetch and non-temporal stores
big_fwd_avx512_loop:
	PREFETCHNTA 512(SI)
	PREFETCHNTA 576(SI)
	PREFETCHNTA 640(SI)
	PREFETCHNTA 704(SI)

	VMOVDQU64 (SI), Z0
	VMOVDQU64 64(SI), Z1
	VMOVDQU64 128(SI), Z2
	VMOVDQU64 192(SI), Z3
	VMOVDQU64 256(SI), Z4
	VMOVDQU64 320(SI), Z5
	VMOVDQU64 384(SI), Z6
	VMOVDQU64 448(SI), Z7

	VMOVNTDQ Z0, (DI)
	VMOVNTDQ Z1, 64(DI)
	VMOVNTDQ Z2, 128(DI)
	VMOVNTDQ Z3, 192(DI)
	VMOVNTDQ Z4, 256(DI)
	VMOVNTDQ Z5, 320(DI)
	VMOVNTDQ Z6, 384(DI)
	VMOVNTDQ Z7, 448(DI)

	ADDQ	$512, SI
	ADDQ	$512, DI
	SUBQ	$512, BX
	JAE	big_fwd_avx512_loop

	SFENCE

	// Restore BX and handle remainder
	ADDQ	$256, BX

	// Store head and tail
	VMOVDQU64 Z28, (R8)
	VMOVDQU64 Z29, 64(R8)
	VMOVDQU64 Z24, -256(R8)(BX*1)
	VMOVDQU64 Z25, -192(R8)(BX*1)
	VMOVDQU64 Z26, -128(R8)(BX*1)
	VMOVDQU64 Z27, -64(R8)(BX*1)

	VZEROUPPER
	RET

// Very large backward copy with non-temporal stores
gobble_big_data_bwd_avx512:
	MOVQ	DI, R8
	ADDQ	BX, DI
	ADDQ	BX, SI

	// Save head (first 256 bytes)
	VMOVDQU64 (R8), Z24
	VMOVDQU64 64(R8), Z25
	VMOVDQU64 128(R8), Z26
	VMOVDQU64 192(R8), Z27

	// Align destination end
	MOVQ	DI, R9
	ANDQ	$-64, DI

	// Save tail
	VMOVDQU64 -64(SI), Z28
	VMOVDQU64 -128(SI), Z29

	// Adjust
	MOVQ	DI, R10
	SUBQ	R8, R10
	SUBQ	R10, SI
	SUBQ	R10, BX
	SUBQ	$256, BX

	// Main backward loop
big_bwd_avx512_loop:
	PREFETCHNTA -512(SI)
	PREFETCHNTA -576(SI)
	PREFETCHNTA -640(SI)
	PREFETCHNTA -704(SI)

	VMOVDQU64 -64(SI), Z0
	VMOVDQU64 -128(SI), Z1
	VMOVDQU64 -192(SI), Z2
	VMOVDQU64 -256(SI), Z3
	VMOVDQU64 -320(SI), Z4
	VMOVDQU64 -384(SI), Z5
	VMOVDQU64 -448(SI), Z6
	VMOVDQU64 -512(SI), Z7

	VMOVNTDQ Z0, -64(DI)
	VMOVNTDQ Z1, -128(DI)
	VMOVNTDQ Z2, -192(DI)
	VMOVNTDQ Z3, -256(DI)
	VMOVNTDQ Z4, -320(DI)
	VMOVNTDQ Z5, -384(DI)
	VMOVNTDQ Z6, -448(DI)
	VMOVNTDQ Z7, -512(DI)

	SUBQ	$512, SI
	SUBQ	$512, DI
	SUBQ	$512, BX
	JAE	big_bwd_avx512_loop

	SFENCE

	ADDQ	$256, BX

	// Store head and tail
	VMOVDQU64 Z28, -64(R8)(BX*1)
	VMOVDQU64 Z29, -128(R8)(BX*1)
	VMOVDQU64 Z24, (R8)
	VMOVDQU64 Z25, 64(R8)
	VMOVDQU64 Z26, 128(R8)
	VMOVDQU64 Z27, 192(R8)

	VZEROUPPER
	RET
