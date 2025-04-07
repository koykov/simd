// func memclrNEON(p []uint64)
TEXT ·memclrNEON(SB),NOSPLIT,$0-24
    MOVD    p_base+0(FP), R0   // point to slice start (RO = &p[0])
    MOVD    p_len+8(FP), R1    // slice len (R1 = len(p))

    // process tail (0-3 items)
    ANDS    $3, R1, R2         // R2 = len % 4
    BEQ     block_processing   // goto main block processing

    MOVD    $0, R3
tail_loop:
    MOVD    R3, (R0)           // clear single item
    ADD     $8, R0             // shift pointer
    SUBS    $1, R2             // reduce counter
    BNE     tail_loop

block_processing:
    // process 4 items per iteration
    LSR     $2, R1             // R1 = R1 >> 2 (count of blocks)
    CBZ     R1, done

    MOVI    V0.D2, #0          // clean up SIMD reg (128 bits)

loop:
    STP     (V0.D, V0.D), [R0], #32  // write 4 items (32 bytes)
    SUBS    $1, R1             // reduce counter
    BNE     loop

done:
    RET
