package memclr64

import "unsafe"

// ClearBytes clears byte array p.
func ClearBytes(p []byte) {
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
	for len(p) > 8 {
		u := *(*uint64)(unsafe.Pointer(&p[0]))
		u = 0
		_ = u
		p = p[8:]
	}
	if len(p) > 4 {
		u := *(*uint32)(unsafe.Pointer(&p[0]))
		u = 0
		_ = u
		p = p[4:]
	}
	switch len(p) {
	case 3:
		p[0], p[1], p[2] = 0, 0, 0
	case 2:
		p[0], p[1] = 0, 0
	case 1:
		p[0] = 0
	}
}
