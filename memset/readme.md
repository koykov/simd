# Memset

Vectorised memory set of array of bytes or uint64 numbers.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/memset"

var a = []uint64{0, ..., 0} // very big slice
memset.Memset64(a, 0xFFFFFFFFFFFFFFFF)
println(a) // [0xFFFFFFFFFFFFFFFF, ..., 0xFFFFFFFFFFFFFFFF]
```

The solution is optimized for very long input data.
