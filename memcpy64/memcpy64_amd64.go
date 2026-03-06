package memcpy64

import "golang.org/x/sys/cpu"

var funcAMD64 func([]uint64, []uint64)

func init() {
	if cpu.X86.HasAVX512F {
		funcAMD64 = memcpyAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = memcpyAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = memcpySSE2
		return
	}
	funcAMD64 = memcpy64Generic
}

func memcpy64(dst, src []uint64) {
	funcAMD64(dst, src)
}

//go:noescape
func memcpySSE2([]uint64, []uint64)

//go:noescape
func memcpyAVX2([]uint64, []uint64)

//go:noescape
func memcpyAVX512([]uint64, []uint64)
