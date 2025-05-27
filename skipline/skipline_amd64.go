package skipline

import "golang.org/x/sys/cpu"

var funcAMD64 func([]byte) int

func init() {
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		funcAMD64 = skiplineAVX512
		return
	}
	if cpu.X86.HasAVX2 {
		funcAMD64 = skiplineAVX2
		return
	}
	if cpu.X86.HasSSE2 {
		funcAMD64 = skiplineSSE2
		return
	}
	funcAMD64 = skiplineGeneric
}

func skipline(b []byte) (i int) {
	n := len(b)
	if n < 64 {
		return skiplineGeneric(b)
	}
	n64 := n - n%64
	if i = funcAMD64(b[:n64]); i >= 0 {
		return
	}
	if i = skiplineGeneric(b[n64:]); i >= 0 {
		return n64 + i
	}
	return -1
}

//go:noescape
func skiplineSSE2(b []byte) int

//go:noescape
func skiplineAVX2(b []byte) int

//go:noescape
func skiplineAVX512(b []byte) int
