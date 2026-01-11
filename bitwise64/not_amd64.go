package bitwise64

import "golang.org/x/sys/cpu"

var funcNotAMD64 func([]uint64)

func init() {
	if cpu.X86.HasAVX512F {
		funcNotAMD64 = notAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcNotAMD64 = notAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcNotAMD64 = notSSE2
		return
	}
	funcNotAMD64 = notGeneric
}

func not(a []uint64) {
	funcNotAMD64(a)
}

//go:noescape
func notSSE2(a []uint64)

//go:noescape
func notAVX2(a []uint64)

//go:noescape
func notAVX512(a []uint64)
