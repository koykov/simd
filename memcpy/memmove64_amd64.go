package memcpy

import (
	"unsafe"

	"golang.org/x/sys/cpu"
)

var mvfuncAMD64 func(dst, src unsafe.Pointer, n uintptr)

func init() {
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VL {
		mvfuncAMD64 = memmoveAVX512
		return
	}
	mvfuncAMD64 = memmove64Generic
}

func memmove64(dst, src []uint64) {
	n := len(dst)
	if n < len(src) {
		n = len(src)
	}
	mvfuncAMD64(unsafe.Pointer(&dst[0]), unsafe.Pointer(&src[0]), uintptr(n*8))
}

//go:noescape
func memmoveAVX512(dst, src unsafe.Pointer, n uintptr)
