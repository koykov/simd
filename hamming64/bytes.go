package hamming64

import (
	"math/bits"
	"unsafe"
)

// DistanceBytes returns the Hamming distance between two byte slices.
func DistanceBytes(a, b []byte) (r int) {
	al, bl := len(a), len(b)
	mn := minI(al, bl)
	if mn > 8 {
		mn -= mn % 8
		mn /= 8
		type sh struct {
			p    uintptr
			l, c int
		}
		ah := sh{p: uintptr(unsafe.Pointer(&a[0])), l: mn, c: mn}
		a64 := *(*[]uint64)(unsafe.Pointer(&ah))
		bh := sh{p: uintptr(unsafe.Pointer(&b[0])), l: mn, c: mn}
		b64 := *(*[]uint64)(unsafe.Pointer(&bh))
		r = Distance(a64, b64)
	}

	a, b = a[mn*8:], b[mn*8:]
	mn = minI(len(a), len(b))
	var i int
	for i = 0; i < mn; i++ {
		r += bits.OnesCount8(a[i] ^ b[i])
	}
	rest := a[i:]
	if bl > al {
		rest = b[i:]
	}
	for i = 0; i < len(rest); i++ {
		r += bits.OnesCount8(rest[i])
	}
	return
}
