// func memclrPPC64LE(p []uint64)
TEXT ·memclrPPC64LE(SB),NOSPLIT,$0-24
    MOVD    p+0(FP), R3        // point to slice start (R3 = &p[0])
    MOVD    p_len+8(FP), R4    // slice len (R4 = len(p))

    // process tail (0-3 items)
    ANDCC   $3, R4, R5         // R5 = len % 4
    BEQ     block_processing   // goto main block processing

    MOVD    $0, R6
tail_loop:
    MOVD    R6, (R3)           // clear single item
    ADD     $8, R3             // shift pointer
    SUBF    $1, R5, R5         // reduce counter (SUBF = subtract from)
    CMP     R5, $0
    BNE     tail_loop

block_processing:
    // process 4 items per iteration
    SRD     $2, R4             // R4 = R4 >> 2 (count of blocks)
    CMP     R4, $0
    BEQ     done

    XXLXOR  VS32, VS32, VS32   // clean up SIMD reg VS32 (128 bits)

loop:
    STXVD2X VS32, (R3)         // write 2 items (16 bytes)
    ADD     $16, R3
    STXVD2X VS32, (R3)         // write 2 items (16 bytes)
    ADD     $16, R3
    SUBF    $1, R4, R4         // reduce counter
    CMP     R4, $0
    BNE     loop

done:
    RET
