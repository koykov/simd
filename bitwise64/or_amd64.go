package bitwise64

import "golang.org/x/sys/cpu"

var funcAMD64 func([]uint64, []uint64)

func init() {
	if cpu.X86.HasAVX512F {
		funcAMD64 = orAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = orAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = orSSE2
		return
	}
	funcAMD64 = orGeneric
}

func or(a, b []uint64) {
	funcAMD64(a, b)
}

//go:noescape
func orSSE2(a, b []uint64)

//go:noescape
func orAVX2(a, b []uint64)

//go:noescape
func orAVX512(a, b []uint64)
