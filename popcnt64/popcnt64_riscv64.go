package popcnt64

import "golang.org/x/sys/cpu"

var funcRISCV64 func([]uint64) uint64

func init() {
	if cpu.RISCV64.HasV {
		funcRISCV64 = popcnt64RISCV64
		return
	}
	funcRISCV64 = countGeneric
}

func count(data []uint64) uint64 {
	return funcRISCV64(data)
}

//go:noescape
func countRISCV64([]uint64) uint64
