package popcnt64

import "golang.org/x/sys/cpu"

var funcARM64 func([]uint64) uint64

func init() {
	if cpu.ARM64.HasASIMD {
		funcARM64 = countNEON
		return
	}
	funcARM64 = countGeneric
}

func count(data []uint64) uint64 {
	return funcARM64(data)
}

//go:noescape
func countNEON([]uint64) uint64
