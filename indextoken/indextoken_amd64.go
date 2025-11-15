package indextoken

import "golang.org/x/sys/cpu"

var funcAMD64 func([]byte) int

func init() {
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		funcAMD64 = indextokenAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = indextokenAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = indextokenSSE2
		return
	}
	funcAMD64 = indextokenGeneric
}

func indextoken(b []byte) int {
	return funcAMD64(b)
}

//go:noescape
func indextokenSSE2([]byte) int

//go:noescape
func indextokenAVX2([]byte) int

//go:noescape
func indextokenAVX512([]byte) int
