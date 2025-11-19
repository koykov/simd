package indexbyte

import "golang.org/x/sys/cpu"

var funcARM64 func([]byte, byte) int

func init() {
	if cpu.ARM64.HasASIMD {
		funcARM64 = indexbyteNEON
		return
	}
	funcARM64 = indexbyteGeneric
}

func indexbyte(b []byte, x byte) int {
	return funcARM64(b, x)
}

//go:noescape
func indexbyteNEON([]byte, byte)
