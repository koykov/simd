package memclr64

import "golang.org/x/sys/cpu"

var funcAMD64 func([]uint64)

func init() {
	if cpu.X86.HasAVX512F {
		funcAMD64 = memclrAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = memclrAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = memclrSSE2
		return
	}
	funcAMD64 = memclrGeneric
}

func memclr64(p []uint64) {
	funcAMD64(p)
}

//go:noescape
func memclrSSE2([]uint64)

//go:noescape
func memclrAVX2([]uint64)

//go:noescape
func memclrAVX512([]uint64)
