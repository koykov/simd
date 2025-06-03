package indexbyte

import "golang.org/x/sys/cpu"

var funcnePPC64LE func([]byte, byte) int

func init() {
	if cpu.PPC64.HasVMX && cpu.PPC64.HasVSX {
		funcnePPC64LE = indexbytenePPC64LE
		return
	}
	funcnePPC64LE = indexbyteGeneric
}

func indexbytene(b []byte, x byte) int {
	return funcnePPC64LE(b, x)
}

//go:noescape
func indexbytenePPC64LE([]byte, byte) int
