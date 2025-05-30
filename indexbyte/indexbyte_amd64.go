package indexbyte

import "golang.org/x/sys/cpu"

var funcAMD64 func([]byte, byte) int

func init() {
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		funcAMD64 = indexbyteAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = indexbyteAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = indexbyteSSE2
		return
	}
	funcAMD64 = indexbyteGeneric
}

func indexbyte(b []byte, x byte) int {
	return funcAMD64(b, x)
}

//go:noescape
func indexbyteSSE2([]byte, byte) int

//go:noescape
func indexbyteAVX2([]byte, byte) int

//go:noescape
func indexbyteAVX512([]byte, byte) int
