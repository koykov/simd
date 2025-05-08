package memclr64

import "unsafe"

// ClearUnsafe clears block of memory with given size pointed to by ptr.
// !CAUTION: memory block must not contain heap pointers!
func ClearUnsafe(ptr unsafe.Pointer, len_ int) {
	type sh struct {
		p    uintptr
		l, c int
	}
	h := sh{p: uintptr(ptr), l: len_, c: len_}
	b := *(*[]byte)(unsafe.Pointer(&h))
	ClearBytes(b)
}
