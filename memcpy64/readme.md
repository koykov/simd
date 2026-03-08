# Memcpy64

Vectorised memory copying of array of uint64 number.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/memcpy64"

var a = []uint64{0xFFFFFFFFFFFFFFFF, ..., 0xFFFFFFFFFFFFFFFF} // very big slice
dst := make([]uint64, len(a))
memcpy64.Copy(dst, a)
println(dst) // the same contents
```

The solution is optimized for very long input data.

## Copy bytes slice

Package also provides [`CopyBytes`](bytes.go) method, that copies bytes slice.

## Copy raw memory

Package provides unsafe version [CopyUnsafe](unsafe.go) method. Use with caution! Pointers must point to a memory blocks
without heap pointers, memory leak may occur otherwise.
