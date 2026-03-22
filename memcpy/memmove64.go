package memcpy

import "unsafe"

func Move64(dst, src []uint64) {
	memmove64(dst, src)
}

//go:noescape
//go:linkname memmove64Generic runtime.memmove
func memmove64Generic(dst, src unsafe.Pointer, n uintptr)
