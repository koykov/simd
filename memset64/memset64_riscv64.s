// func memsetRISCV64(p []uint64, val uint64)
TEXT ·memsetRISCV64(SB),NOSPLIT,$0-32
    MOV     p+0(FP), A0        // A0 = &p[0]
    MOV     p_len+8(FP), A1    // A1 = len(p)
    MOV     val+24(FP), A2     // A2 = val

    // process tail (0-7 items)
    ANDI    A1, 7, A3          // A3 = len % 8
    BEQZ    A3, block_processing // goto main block processing

tail_loop:
    SD      A2, (A0)           // store val
    ADDI    A0, 8, A0          // shift pointer
    ADDI    A3, -1, A3         // reduce counter
    BNEZ    A3, tail_loop

block_processing:
    // process 8 items per iteration
    SRLI    A1, 3, A4          // A4 = len / 8 (count of blocks)
    BEQZ    A4, done

    // Setup vector registers
    CSRRWI  0, vtype, 0b011    // SEW=64, LMUL=1 (vtype = 0b00011011)
    VMV     V0, A2             // Broadcast val to vector reg V0

    // Calculate end pointer
    SLLI    A4, 3, A5          // A5 = A4 * 8 (items count)
    SLLI    A5, 3, A5          // A5 = A5 * 8 (bytes count)
    ADD     A0, A5, A6         // A6 = end pointer

vector_loop:
    VSE64_V V0, (A0)           // write 8 items (512 bits)
    ADDI    A0, 64, A0         // shift pointer
    BLT     A0, A6, vector_loop

done:
    RET
