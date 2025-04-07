// func memclrRISCV64(p []uint64)
TEXT ·memclrRISCV64(SB),NOSPLIT,$0-24
    MOV     p+0(FP), A0        // point to slice start (AO = &p[0])
    MOV     p_len+8(FP), A1    // slice len (A1 = len(p))

    // process tail (0-7 items)
    ANDI    A1, 7, A2          // A2 = len % 8
    BEQZ    A2, block_processing // goto main block processing

    MV      X0, A3
tail_loop:
    SD      A3, (A0)           // clear single item
    ADDI    A0, 8, A0          // shift pointer
    ADDI    A2, -1, A2         // reduce counter
    BNEZ    A2, tail_loop

block_processing:
    // process 8 items per iteration
    SRLI    A1, 3, A4          // A1 = A1 >> 2 (count of blocks)
    BEQZ    A4, done

    CSRRWI  0, vtype, 0b011    // SEW=64, LMUL=1 (vtype = 0b00011011)
    VMV     V0, X0             // cleanup vector reg V0

    // amount of items for vectorising
    SLLI    A4, 3, A5          // A5 = A4 * 8
    ADD     A0, A5, A6         // A6 = destination

vector_loop:
    VSE64_V V0, (A0)           // write 8 items (512 bits)
    ADD     A0, A5, A0         // shift counter
    BLT     A0, A6, vector_loop

done:
    RET
