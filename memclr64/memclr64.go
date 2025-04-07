package memclr64

import "unsafe"

func Clear(p []byte) {
	const blocksz = 32
	n := len(p)
	if n == 0 {
		return
	}
	if n >= blocksz {
		n64 := (n - n%blocksz) / 8
		type sh struct {
			p    uintptr
			l, c int
		}
		h := sh{p: uintptr(unsafe.Pointer(&p[0])), l: n64, c: n64}
		p64 := *(*[]uint64)(unsafe.Pointer(&h))
		memclr64(p64)
		p = p[n64*8:]
		n = len(p)
	}
	if n == 0 {
		return
	}
	_ = p[n-1]
	for i := 0; i < len(p); i++ {
		p[i] = 0
	}
}

func memclr64Generic(p []uint64) {
	_ = p[len(p)-1]
	for i := 0; i < len(p); i++ {
		p[i] = 0
	}
}
