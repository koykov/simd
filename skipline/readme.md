# Skip line

Vectorised line skipping - finds position of last symbol in string (including NL\CR).
May be helpful to skip comments.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/skipline"

var b = []byte{"Lorem ipsum dolor sit amet ... \n"} // very big string (slice)
i := skipline.Index(b)
println(i) // index of first symbol after `\n`
```

The solution is optimized for very long input data.
