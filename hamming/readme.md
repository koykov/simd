# Hamming

Vectorised hamming distance calculation of arrays of bytes or uint64 numbers.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/hamming"

var a = []uint64{0xFFFFFFFFFFFFFFFF, ..., 0xFFFFFFFFFFFFFFFF} // very big slice
var b = []uint64{0x0000000000000000, ..., 0x0000000000000000} // very big slice
dist := hamming.Distance64(a, b)
println(dist) // number of different bits after xor
```

The solution is optimized for very long input data.
