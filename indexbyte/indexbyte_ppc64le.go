package indexbyte

import "golang.org/x/sys/cpu"

var funcPPC64LE func([]byte, byte) int

func init() {
	if cpu.PPC64.HasVMX && cpu.PPC64.HasVSX {
		funcPPC64LE = indexbytePPC64LE
		return
	}
	funcPPC64LE = indexbyteGeneric
}

func indexbyte(b []byte, x byte) int {
	return funcPPC64LE(b, x)
}

//go:noescape
func indexbytePPC64LE([]byte, byte) int
