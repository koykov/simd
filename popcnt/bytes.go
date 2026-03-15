package popcnt

import (
	"math/bits"
	"unsafe"
)

// Count calculates population count in array p.
func Count(p []byte) uint64 {
	const blocksz = 32
	n := len(p)
	if n == 0 {
		return 0
	}
	var r uint64
	if n >= blocksz {
		n64 := (n - n%blocksz) / 8
		type sh struct {
			p    uintptr
			l, c int
		}
		h := sh{p: uintptr(unsafe.Pointer(&p[0])), l: n64, c: n64}
		p64 := *(*[]uint64)(unsafe.Pointer(&h))
		r = count(p64)
		p = p[n64*8:]
		n = len(p)
	}
	if n == 0 {
		return r
	}
	_ = p[n-1]
	for i := 0; i < len(p); i++ {
		r += uint64(bits.OnesCount8(p[i]))
	}
	return r
}
