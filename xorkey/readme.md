# Xorkey

Vectorised XOR operations over bytes data and given key.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/xorkey"

data := []byte("Lorem ipsum dolor sit amet...") // very big slice
key := []byte("LfnboP5fe869pbsHlYtkl5zYapd8YFT6")
xorkey.Encode32(data, [32]byte(key))
println(data) // []byte{0x0, 0x9, 0x1c, 0x7, 0x2, 0x70, 0x5c, 0x16, 0x16, 0x4d, 0x5b, 0x19, 0x14, 0xd, 0x1f, 0x27, 0x1e, 0x79, 0x7, 0x2, 0x18, 0x15, 0x1b, 0x34, 0x4, 0x4, 0x4a, 0x16, 0x77}

xorkey.Encode32(data, [32]byte(key)) // second apply decodes data
println(data) // Lorem ipsum dolor sit amet...
```

The solution is optimized for very long input data.

Also available method for 64-byte length key `Encode64`.
