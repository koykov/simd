package memset

import "unsafe"

// Memset fills array p with given value.
func Memset(p []byte, value byte) {
	const blocksz = 32
	n := len(p)
	if n == 0 {
		return
	}
	if n >= blocksz {
		value64 := uint64(value)<<56 | uint64(value)<<48 | uint64(value)<<40 | uint64(value)<<32 | uint64(value)<<24 |
			uint64(value)<<16 | uint64(value)<<8 | uint64(value)
		n64 := (n - n%blocksz) / 8
		type sh struct {
			p    uintptr
			l, c int
		}
		h := sh{p: uintptr(unsafe.Pointer(&p[0])), l: n64, c: n64}
		p64 := *(*[]uint64)(unsafe.Pointer(&h))
		memset64(p64, value64)
		p = p[n64*8:]
		n = len(p)
	}
	if n == 0 {
		return
	}
	_ = p[n-1]
	for i := 0; i < len(p); i++ {
		p[i] = value
	}
}
