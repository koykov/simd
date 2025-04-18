package memset64

import "golang.org/x/sys/cpu"

var funcAMD64 func([]uint64, uint64)

func init() {
	if cpu.X86.HasAVX512F {
		funcAMD64 = memsetAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = memsetAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = memsetSSE2
		return
	}
	funcAMD64 = memset64Generic
}

func memset64(p []uint64, value uint64) {
	funcAMD64(p, value)
}

//go:noescape
func memsetSSE2([]uint64, uint64)

//go:noescape
func memsetAVX2([]uint64, uint64)

//go:noescape
func memsetAVX512([]uint64, uint64)
