package memcpy

import (
	"unsafe"

	"golang.org/x/sys/cpu"
)

var memmoveBits uint8

const (
	avxSupported     = 1 << 0
	repmovsPreferred = 1 << 1
)

var avx512Supported bool

func init() {
	avx512Supported = cpu.X86.HasAVX512F
}

//go:noescape
func memmoveAVX512(to, from unsafe.Pointer, n uintptr)

//go:noescape
//go:linkname memmove runtime.memmove
func memmove(to, from unsafe.Pointer, n uintptr)
