package bitwise

import "unsafe"

func Not64(a []uint64) {
	not(a)
}

func Not(a []byte) {
	n := len(a)
	var n8 int
	if n > 8 {
		n -= n % 8
		n8 = n
		n /= 8
		type sh struct {
			p    uintptr
			l, c int
		}
		ah := sh{p: uintptr(unsafe.Pointer(&a[0])), l: n, c: n}
		a64 := *(*[]uint64)(unsafe.Pointer(&ah))
		not(a64)
	}

	a = a[n8:]
	n = len(a)
	var i int
	for i = 0; i < n; i++ {
		a[i] = ^a[i]
	}
}

func notGeneric(a []uint64) {
	for i := 0; i < len(a); i++ {
		a[i] = ^a[i]
	}
}

var _ = Not64
