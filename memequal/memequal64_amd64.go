package memequal

import "golang.org/x/sys/cpu"

var funcAMD64 func([]uint64, []uint64) bool

func init() {
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW {
		funcAMD64 = memequalAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = memequalAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = memequalSSE2
		return
	}
	funcAMD64 = memequal64Generic
}

func memequal64(dst, src []uint64) bool {
	return funcAMD64(dst, src)
}

//go:noescape
func memequalSSE2([]uint64, []uint64) bool

//go:noescape
func memequalAVX2([]uint64, []uint64) bool

//go:noescape
func memequalAVX512([]uint64, []uint64) bool
