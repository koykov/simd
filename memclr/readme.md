# Memclr64

Vectorised memory clearing of array of uint64 number.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/memclr64"

var a = []uint64{0xFFFFFFFFFFFFFFFF, ..., 0xFFFFFFFFFFFFFFFF} // very big slice
memclr64.Clear(a)
println(a) // [0, ..., 0]
```

The solution is optimized for very long input data.

## Clear bytes slice

Package also provides [`ClearBytes`](bytes.go) method, that clears bytes slice. It uses default `Clear` method inside for
clearing and clear rest of bytes in simple loop.

## Clear raw memory

Package provides unsafe version [CleanUnsafe](unsafe.go) method. Use with caution! Pointer must point to a memory block
without heap pointers, memory leak may occur otherwise.
