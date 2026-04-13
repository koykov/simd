# Memequal

Vectorised memory equality check of array of bytes or uint64 numbers.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/memequal"

var a = []uint64{0xFFFFFFFFFFFFFFFF, ..., 0xFFFFFFFFFFFFFFFF} // very big slice
var b = []uint64{0xFFFFFFFFFFFFFFFF, ..., 0xFFFFFFFFFFFFFFFF} // very big slice
r := memequal.Equal64(a, b)
println(r) // true
```

The solution is optimized for very long input data.

## Copy bytes slice

Package also provides [`Equal`](bytes.go) method, that checks equality of bytes slices.

## Copy raw memory

Package provides unsafe version [EqualUnsafe](unsafe.go) method. Use with caution!
