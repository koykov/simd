package popcnt64

import "golang.org/x/sys/cpu"

var funcAMD64 func([]uint64) uint64

func init() {
	if cpu.X86.HasAVX512F {
		funcAMD64 = countAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = countAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = countSSE2
		return
	}
	funcAMD64 = countGeneric
}

func count(data []uint64) uint64 {
	return funcAMD64(data)
}

//go:noescape
func countSSE2([]uint64) uint64

//go:noescape
func countAVX2([]uint64) uint64

//go:noescape
func countAVX512([]uint64) uint64
