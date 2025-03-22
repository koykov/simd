#include "textflag.h"

TEXT ·countPPC64LE(SB), NOSPLIT, $0-32
    MOVD data+0(FP), R3   // point to slice start (R3 = &data[0])
    MOVD len+8(FP), R4    // slice len (R4 = len(data))
    MOVD $0, R5           // reset acc (R5 = 0)

    // check if slice len is less than 2 (VSX use is reasonable)
    CMP R4, $2
    BLT remainder         // go to remainder label

    // prepare VSX regs
    LXVD2X (R3), VS32     // load 2 numbers (128 бит) to VS32
    ADD $16, R3           // shift to next block (16 bytes)

    VSPLTISB $0x55, VS33  // init VS33 with mask 0x5555555555555555
    VSPLTISB $0x33, VS34  // init VS34 with mask 0x3333333333333333
    VSPLTISB $0x0F, VS35  // init VS35 with mask 0x0F0F0F0F0F0F0F0F

    VAND VS32, VS33, VS36 // VS36 = VS32 & 0x5555555555555555
    VSRD $1, VS32, VS37   // VS37 = VS32 >> 1
    VAND VS37, VS33, VS37 // VS37 = (VS32 >> 1) & 0x5555555555555555
    VADDUWM VS36, VS37, VS32 // VS32 = VS36 + VS37

    VAND VS32, VS34, VS36 // VS36 = VS32 & 0x3333333333333333
    VSRD $2, VS32, VS37   // VS37 = VS32 >> 2
    VAND VS37, VS34, VS37 // VS37 = (VS32 >> 2) & 0x3333333333333333
    VADDUWM VS36, VS37, VS32 // VS32 = VS36 + VS37

    VAND VS32, VS35, VS36 // VS36 = VS32 & 0x0F0F0F0F0F0F0F0F
    VSRD $4, VS32, VS37   // VS37 = VS32 >> 4
    VAND VS37, VS35, VS37 // VS37 = (VS32 >> 4) & 0x0F0F0F0F0F0F0F0F
    VADDUWM VS36, VS37, VS32 // VS32 = VS36 + VS37

    // sum to VS32
    VADDUWM VS32, VS32, VS32 // VS32 += VS32

    // switch to next block
    SUBC R4, $2, R4       // R4 -= 2
    CMP R4, $2
    BGE loop              // repeat till R4 >= 2

    // sum VS32 to R5
    MFVSRD VS32, R6       // load low 64 bits VS32 to R6
    ADD R6, R5, R5        // R5 += R6

remainder:
    // process remain number (less than 2)
    CMP R4, $0
    BEQ done

    MOVD $0, R6
remainder_loop:
    LD (R3), R7           // load to R7
    ADD $8, R3            // shift to next number
    POPCNTD R7, R8        // count set bits
    ADD R8, R5, R5        // R5 += R8
    SUBC R4, $1, R4       // R4 -= 1
    BNE remainder_loop

done:
    MOVD R5, ret+24(FP)
    RET
