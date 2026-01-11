package bitwise64

import "golang.org/x/sys/cpu"

var funcXorAMD64 func([]uint64, []uint64)

func init() {
	if cpu.X86.HasAVX512F {
		funcXorAMD64 = xorAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcXorAMD64 = xorAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcXorAMD64 = xorSSE2
		return
	}
	funcXorAMD64 = xorGeneric
}

func xor(a, b []uint64) {
	funcXorAMD64(a, b)
}

//go:noescape
func xorSSE2(a, b []uint64)

//go:noescape
func xorAVX2(a, b []uint64)

//go:noescape
func xorAVX512(a, b []uint64)
