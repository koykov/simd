// func memsetPPC64LE(p []uint64, val uint64)
TEXT ·memsetPPC64LE(SB),NOSPLIT,$0-32
    MOVD    p+0(FP), R3        // R3 = &p[0]
    MOVD    p_len+8(FP), R4    // R4 = len(p)
    MOVD    val+24(FP), R5     // R5 = val

    // process tail (0-3 items)
    ANDCC   $3, R4, R6         // R6 = len % 4
    BEQ     block_processing   // goto main block processing

tail_loop:
    MOVD    R5, (R3)           // store val
    ADD     $8, R3             // shift pointer
    SUBF    $1, R6, R6         // reduce counter
    CMP     R6, $0
    BNE     tail_loop

block_processing:
    // process 4 items per iteration
    SRD     $2, R4             // R4 = R4 >> 2 (count of blocks)
    CMP     R4, $0
    BEQ     done

    // Broadcast val to SIMD register
    MTVSRD  R5, VS32           // VS32 = [val, val]
    XXPERMDI VS32, VS32, 0, VS32 // Duplicate val in VS32

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
