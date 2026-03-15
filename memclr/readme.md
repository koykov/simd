# Memclr

Vectorised memory clearing of array of bytes or uint64 numbers.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/memclr"

var a = []uint64{0xFFFFFFFFFFFFFFFF, ..., 0xFFFFFFFFFFFFFFFF} // very big slice
memclr.Clear64(a)
println(a) // [0, ..., 0]
```

The solution is optimized for very long input data.

## Clear bytes slice

Package also provides [`Clear`](bytes.go) method, that clears bytes slice.

## Clear raw memory

Package provides unsafe version [ClearUnsafe](unsafe.go) method. Use with caution! Pointer must point to a memory block
without heap pointers, memory leak may occur otherwise.
