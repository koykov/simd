package memclr64

import "golang.org/x/sys/cpu"

var funcARM64 func([]uint64)

func init() {
	if cpu.ARM64.HasASIMD {
		funcARM64 = memclrNEON
		return
	}
	funcARM64 = memclr64Generic
}

func memclr64(data []uint64) {
	funcARM64(data)
}

//go:noescape
func memclrNEON([]uint64)
