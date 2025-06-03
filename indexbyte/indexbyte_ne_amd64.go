package indexbyte

import "golang.org/x/sys/cpu"

var funcneAMD64 func([]byte, byte) int

func init() {
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		funcneAMD64 = indexbyteneAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcneAMD64 = indexbyteneAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcneAMD64 = indexbyteneSSE2
		return
	}
	funcneAMD64 = indexbyteneGeneric
}

func indexbytene(b []byte, x byte) int {
	return funcneAMD64(b, x)
}

//go:noescape
func indexbyteneSSE2([]byte, byte) int

//go:noescape
func indexbyteneAVX2([]byte, byte) int

//go:noescape
func indexbyteneAVX512([]byte, byte) int
