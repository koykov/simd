package hamming64

import "golang.org/x/sys/cpu"

var funcAMD64 func([]uint64, []uint64) int

func init() {
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VPOPCNTDQ {
		funcAMD64 = hammingAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = hammingAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = hammingSSE2
		return
	}
	funcAMD64 = hammingGeneric
}

func hamming(a, b []uint64) int {
	return funcAMD64(a, b)
}

//go:noescape
func hammingSSE2(a, b []uint64) int

//go:noescape
func hammingAVX2(a, b []uint64) int

//go:noescape
func hammingAVX512(a, b []uint64) int
