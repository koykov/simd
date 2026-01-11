package bitwise64

import "golang.org/x/sys/cpu"

var funcAndAMD64 func([]uint64, []uint64)

func init() {
	if cpu.X86.HasAVX512F {
		funcAndAMD64 = andAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAndAMD64 = andAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAndAMD64 = andSSE2
		return
	}
	funcAndAMD64 = andGeneric
}

func and(a, b []uint64) {
	funcAndAMD64(a, b)
}

//go:noescape
func andSSE2(a, b []uint64)

//go:noescape
func andAVX2(a, b []uint64)

//go:noescape
func andAVX512(a, b []uint64)
