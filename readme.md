# SIMD toolkit

Collection of various vectorised functions. Currently supported functions:
* [Popcnt64](popcnt64) - count number of set bits in arrays of 64-bit unsigned integers
* [Memclr64](memclr64) - clear arrays of 64-bit unsigned integers
* [Memset64](memclr64) - fill arrays of 64-bit unsigned integers
* [Hamming64](hamming64) - calculate Hamming distance of 64-bit unsigned integers
* [SkipLine](skipline) - find end of line
* [Indexbyte](indexbyte) - find position of given byte in bytes slice
* ...

## Supported architectures/instructions

Currently supported arch and instructions sets:
* AMD64
  * SSE2-SSE4.2
  * AVX2
  * AVX512
* ARM64
  * NEON/ASIMD
* PPC64LE
  * VMX/VSX
* RISCV64
  * V

All AMD64 solutions supports fallback mode - checks at init supported instructions sets and choose the optimal:
* use AVX512 if possible
* use AVX2 if possible and not possible AVX512
* use SSE2-SSE4.2 if not possible AVX2/AVX512
* use generic (pure Go) if not possible SSE2-SSE4.2
