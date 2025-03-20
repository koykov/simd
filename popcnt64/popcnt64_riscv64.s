#include "textflag.h"

TEXT ·popcnt64RISCV64(SB), NOSPLIT, $0-32
    MOV data+0(FP), A0   // // point to slice start (A0 = &data[0])
    MOV len+8(FP), A1    // slice len (A1 = len(data))
    MOV $0, A2           // reset acc (A2 = 0)

    // check if slice len is less than 4
    LI  A3, 4
    BLT A1, A3, remainder // go to remainder label

    // pepare V regs
    VSETVLI A3, ZERO, E64, M4  // set vector len (4 64 bit number)
    VMV V0, ZERO               // clear V0 (acc)

loop:
    VLE64_V V4, (A0)           // load 4 numbers (256 bits) ti V4
    ADD $32, A0                // shift to next block (32 bytes)

    VPOPCNT_V V4, V5           // count set bits in V4, store result to V5
    VADD_VV V0, V5, V0         // V0 += V5

    // shift to next block
    SUB A1, A3, A1             // A1 -= 4
    BGE A1, A3, loop           // repeat

    // sum V0 to A2
    VREDSUM_VS V0, V0, V0      // sum to V0
    VMV_X_S A4, V0             // load reault to A4
    ADD A4, A2, A2             // A2 += A4

remainder:
    // process remain number (less than 4)
    BEQ A1, ZERO, done

    LD  A4, 0(A0)              // load single number to A4
    POPCNT A4, A5              // count set bits in A4, store result to A5
    ADD A5, A2, A2             // A2 += A5
    ADD $8, A0                 // shift to next number
    SUB A1, 1, A1              // A1 -= 1
    J remainder                // repeat

done:
    MOV A2, ret+24(FP)
    RET
