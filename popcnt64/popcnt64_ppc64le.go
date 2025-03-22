package popcnt64

import "golang.org/x/sys/cpu"

var funcPPC64LE func([]uint64) uint64

func init() {
	if cpu.PPC64.IsPOWER8 {
		funcPPC64LE = funcPPC64LE
		return
	}
	funcPPC64LE = countGeneric
}

func count(data []uint64) uint64 {
	return funcPPC64LE(data)
}

func countPPC64LE([]uint64) uint64
