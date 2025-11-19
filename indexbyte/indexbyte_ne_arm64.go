package indexbyte

import "golang.org/x/sys/cpu"

var funcneARM64 func([]byte, byte) int

func init() {
	if cpu.ARM64.HasASIMD {
		funcneARM64 = indexbyteneNEON
		return
	}
	funcneARM64 = indexbyteneGeneric
}

func indexbytene(b []byte, x byte) int {
	return funcneARM64(b, x)
}

//go:noescape
func indexbyteneNEON([]uint64, byte)
