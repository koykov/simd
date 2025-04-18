# Memset64

Vectorised memory set of array of uint64 number.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/memset64"

var a = []uint64{0, ..., 0} // very big slice
memset64.Memset(a, 0xFFFFFFFFFFFFFFFF)
println(a) // [0xFFFFFFFFFFFFFFFF, ..., 0xFFFFFFFFFFFFFFFF]
```

The solution is optimized for very long input data.
