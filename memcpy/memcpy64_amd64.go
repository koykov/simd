package memcpy

import (
	"unsafe"

	"golang.org/x/sys/cpu"
)

var funcAMD64 func([]uint64, []uint64)

func init() {
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VL {
		funcAMD64 = memcpyAVX512
		return
	}
	funcAMD64 = memcpy64Generic
}

func memcpy64(dst, src []uint64) {
	funcAMD64(dst, src)
}

func memcpyAVX512(dst, src []uint64) {
	n, m := len(dst), len(src)
	if n == 0 || m == 0 {
		return
	}
	if m < n {
		n = m
	}
	memmoveAVX512(unsafe.Pointer(&dst[0]), unsafe.Pointer(&src[0]), uintptr(n*8))
}

//go:noescape
func memmoveAVX512(dst, src unsafe.Pointer, n uintptr)
