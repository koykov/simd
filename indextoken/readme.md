# Indextoken

Vectorised token index and tokenizer. Tokens are a string literals between separator symbols `.`, `[`, `]` and `@`.

## Usage

The minimal working example:
```go
import "github.com/koykov/simd/indextoken"

var a = []byte("very long string and finally the token separator. the rest of slice") // very big slice
//                                                              ^
i := indextoken.Index(a)
println(i) // position of first token separator.
```

The solution is optimized for very long input data.

## Tokenizer

Method `Index` just returns position of nearest separator. For handy work with tokens the package also provides
`Tokenizer` it returns tokens till end of the input data. Example:
```go
import "github.com/koykov/simd/indextoken"

var a = []byte("api.v2.users[42].profile.email@work")
var t indextoken.Tokenizer[[]byte]
for {
	if token := t.Next(a); len(token) > 0 {
		println(token) // will print strings: "api" "v2" "users" "42" "profile" "email" "work"
    }
}
```
