# Popcnt64

Vectorised count number of set bits in arrays of 64-bit unsigned integers.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/popcnt64"

var a = []uint64{0xFFFFFFFFFFFFFFFF, 0x0000000000000000, 0x5555555555555555, 0xAAAAAAAAAAAAAAAA}
println(popcnt64.Popcnt64(a)) // 128
```
, but real power of the solution is revealed by the large input arrays.
