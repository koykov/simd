package memcpy

import "unsafe"

// CopyUnsafe copies block of data from src pointer with length len_ to dst.
// !CAUTION: memory block must not contain heap pointers!
func CopyUnsafe(dst, src unsafe.Pointer, len_ int) {
	type sh struct {
		p    uintptr
		l, c int
	}
	hdst := sh{p: uintptr(dst), l: len_, c: len_}
	bdst := *(*[]byte)(unsafe.Pointer(&hdst))
	hsrc := sh{p: uintptr(src), l: len_, c: len_}
	bsrc := *(*[]byte)(unsafe.Pointer(&hsrc))
	Copy(bdst, bsrc)
}
