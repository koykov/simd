# Bitwise64

Vectorised bitwise operations over arrays of uint64 number.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/bitwise64"

var a = []uint64{0x00000000FFFFFFFF, ..., 0x00000000FFFFFFFF} // very big slice
var b = []uint64{0xFFFFFFFF00000000, ..., 0xFFFFFFFF00000000} // very big slice
res := bitwise64.Or(a, b)
println(res) // number of merged bits
```

Package support [And](and.go), [Xor](xor.go) and [Not](not.go) operations as well.

The solution is optimized for very long input data.
