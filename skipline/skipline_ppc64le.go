package skipline

import "golang.org/x/sys/cpu"

var funcPPC64LE func([]byte) int

func init() {
	if cpu.PPC64.HasVMX && cpu.PPC64.HasVSX {
		funcPPC64LE = skiplinePPC64LE
		return
	}
	funcPPC64LE = skiplineGeneric
}

func skipline(b []byte) int {
	return funcPPC64LE(b)
}

//go:noescape
func skiplinePPC64LE(b []byte) int
