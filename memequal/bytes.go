package memequal

import (
	"bytes"
	"unsafe"
)

// Equal checks equality of given bytes arrays.
func Equal(a, b []byte) bool {
	return memequal(a, b, memequal64)
}

func memequal(a, b []byte, fn func([]uint64, []uint64) bool) bool {
	const blocksz = 32
	n, m := len(a), len(b)
	if n != m {
		return false
	}
	if m >= blocksz {
		n64 := (m - m%blocksz) / 8
		type sh struct {
			p    uintptr
			l, c int
		}
		hb := sh{p: uintptr(unsafe.Pointer(&b[0])), l: n64, c: n64}
		pb64 := *(*[]uint64)(unsafe.Pointer(&hb))
		ha := sh{p: uintptr(unsafe.Pointer(&a[0])), l: n64, c: n64}
		pa64 := *(*[]uint64)(unsafe.Pointer(&ha))
		if !fn(pa64, pb64) {
			return false
		}
		b = b[n64*8:]
		a = a[n64*8:]
		m = len(b)
	}
	return bytes.Equal(a, b)
}
