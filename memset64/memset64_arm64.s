// func memsetNEON(p []uint64, val uint64)
TEXT ·memsetNEON(SB),NOSPLIT,$0-32
    MOVD    p_base+0(FP), R0   // R0 = &p[0]
    MOVD    p_len+8(FP), R1    // R1 = len(p)
    MOVD    val+24(FP), R2     // R2 = val

    // process tail (0-3 items)
    ANDS    $3, R1, R3         // R3 = len % 4
    BEQ     block_processing   // goto main block processing

tail_loop:
    MOVD    R2, (R0)           // store val
    ADD     $8, R0             // shift pointer
    SUBS    $1, R3             // reduce counter
    BNE     tail_loop

block_processing:
    // process 4 items per iteration
    LSR     $2, R1             // R1 = R1 >> 2 (count of blocks)
    CBZ     R1, done

    // Broadcast val to SIMD register
    DUP     V0.D, R2           // V0 = [val, val]

loop:
    STP     (V0.D, V0.D), [R0], #32  // write 4 items (32 bytes)
    SUBS    $1, R1             // reduce counter
    BNE     loop

done:
    RET
