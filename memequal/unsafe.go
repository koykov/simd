package memequal

import "unsafe"

// EqualUnsafe checks equality of given bytes arrays with length.
func EqualUnsafe(a, b unsafe.Pointer, len_ int) {
	type sh struct {
		p    uintptr
		l, c int
	}
	ha := sh{p: uintptr(a), l: len_, c: len_}
	ba := *(*[]byte)(unsafe.Pointer(&ha))
	hb := sh{p: uintptr(b), l: len_, c: len_}
	bb := *(*[]byte)(unsafe.Pointer(&hb))
	Equal(ba, bb)
}
