# SIMD toolkit

Collection of various vectorised functions. Currently supported functions:
* [Bitwise](bitwise) - various bitwise operations over arrays of 64-bit unsigned integers or bytes
* [Popcnt](popcnt) - count number of set bits in arrays of 64-bit unsigned integers or bytes
* [Memclr](memclr) - clear arrays of 64-bit unsigned integers or bytes
* [Memcpy](memcpy) - copy arrays of 64-bit unsigned integers or bytes
* [Memset](memclr) - fill arrays of 64-bit unsigned integers or bytes
* [Hamming](hamming) - calculate Hamming distance of 64-bit unsigned integers or bytes
* [SkipLine](skipline) - find end of line in multi-line bytes slice
* [Indexbyte](indexbyte) - find position of given byte in bytes slice
* [Indextoken](indextoken) - find position of next token in bytes slice
* ...

## Supported architectures/instructions

Currently supported arch and instructions sets:
* AMD64
  * SSE2-SSE4.2
  * AVX2
  * AVX512

All AMD64 solutions supports fallback mode - checks at init supported instructions sets and choose the optimal:
* use AVX512 if possible
* use AVX2 if possible and not possible AVX512
* use SSE2-SSE4.2 if not possible AVX2/AVX512
* use generic (pure Go) if not possible SSE2-SSE4.2
