package bitwise

import "unsafe"

func And64(a, b []uint64) {
	al, bl := len(a), len(b)
	mn := minI(al, bl)
	and(a[:mn], b[:mn])
}

func And(a, b []byte) {
	al, bl := len(a), len(b)
	mn := minI(al, bl)
	var mn8 int
	if mn > 8 {
		mn -= mn % 8
		mn8 = mn
		mn /= 8
		type sh struct {
			p    uintptr
			l, c int
		}
		ah := sh{p: uintptr(unsafe.Pointer(&a[0])), l: mn, c: mn}
		a64 := *(*[]uint64)(unsafe.Pointer(&ah))
		bh := sh{p: uintptr(unsafe.Pointer(&b[0])), l: mn, c: mn}
		b64 := *(*[]uint64)(unsafe.Pointer(&bh))
		and(a64, b64)
	}

	a, b = a[mn8:], b[mn8:]
	mn = minI(len(a), len(b))
	var i int
	for i = 0; i < mn; i++ {
		a[i] &= b[i]
	}
}

func andGeneric(a, b []uint64) {
	al, bl := len(a), len(b)
	mn := minI(al, bl)
	_, _ = a[al-1], b[bl-1]
	for i := 0; i < mn; i++ {
		a[i] &= b[i]
	}
}

var _ = And64
