#include "textflag.h"

TEXT ·popcnt64NEON(SB), NOSPLIT, $0-32
    MOVD data+0(FP), R0   // point to slice start (R0 = &data[0])
    MOVD len+8(FP), R1    // slice len (R1 = len(data))
    MOVD $0, R2           // reset acc (R2 = 0)

    // check if slice len is less than 2
    CMP R1, $2
    BLT remainder         // go to remainder label

    // prepare NEON regs
    VMOV.I64 Q0, $0       // clean reg Q0 (acc)
    VMOV.I64 Q1, $0x5555555555555555  // init Q1 with mask 0x5555555555555555
    VMOV.I64 Q2, $0x3333333333333333  // init Q2 with mask 0x3333333333333333
    VMOV.I64 Q3, $0x0F0F0F0F0F0F0F0F  // init Q3 with mask 0x0F0F0F0F0F0F0F0F

neon_loop:
    // load 2 numbers (128 бит) to Q4
    VLD1.64 {Q4}, [R0]!

    VAND Q4, Q1, Q5       // Q5 = Q4 & 0x5555555555555555
    VSHR.U64 Q4, $1, Q6   // Q6 = Q4 >> 1
    VAND Q6, Q1, Q6       // Q6 = (Q4 >> 1) & 0x5555555555555555
    VADD.I64 Q5, Q6, Q4   // Q4 = Q5 + Q6

    VAND Q4, Q2, Q5       // Q5 = Q4 & 0x3333333333333333
    VSHR.U64 Q4, $2, Q6   // Q6 = Q4 >> 2
    VAND Q6, Q2, Q6       // Q6 = (Q4 >> 2) & 0x3333333333333333
    VADD.I64 Q5, Q6, Q4   // Q4 = Q5 + Q6

    VAND Q4, Q3, Q5       // Q5 = Q4 & 0x0F0F0F0F0F0F0F0F
    VSHR.U64 Q4, $4, Q6   // Q6 = Q4 >> 4
    VAND Q6, Q3, Q6       // Q6 = (Q4 >> 4) & 0x0F0F0F0F0F0F0F0F
    VADD.I64 Q5, Q6, Q4   // Q4 = Q5 + Q6

    // sum to Q0
    VADD.I64 Q0, Q4, Q0   // Q0 += Q4

    // switch to next block
    SUBS R1, $2           // R1 -= 2
    CMP R1, $2
    BGE neon_loop         // repeat till R1 >= 2

    // sum Q0 to R2
    VADD.I64 D0, D1, D0   // sum high and low 64 bits to Q0
    VMOV D0[0], R3        // move result to R3
    ADD R2, R3, R2        // R2 += R3

remainder:
    // process remain number (less than 2)
    CMP R1, $0
    BEQ done

    MOVD $0, R3
remainder_loop:
    LDR R4, [R0], $8      // load to R4
    CLZ R5, R4            // count zeros in high bits
    RSB R5, R5, $64       // count all bits
    ADD R2, R5, R2        // R2 += R5
    SUBS R1, $1           // R1 -= 1
    BNE remainder_loop

done:
    MOVD R2, ret+24(FP)
    RET
