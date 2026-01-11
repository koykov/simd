package bitwise64

import "golang.org/x/sys/cpu"

var funcAMD64 func([]uint64, []uint64)

func init() {
	if cpu.X86.HasAVX512F {
		funcAMD64 = andAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = andAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = andSSE2
		return
	}
	funcAMD64 = andGeneric
}

func and(a, b []uint64) {
	funcAMD64(a, b)
}

//go:noescape
func andSSE2(a, b []uint64)

//go:noescape
func andAVX2(a, b []uint64)

//go:noescape
func andAVX512(a, b []uint64)
