package memset64

import "golang.org/x/sys/cpu"

var funcPPC64LE func([]uint64, uint64)

func init() {
	if cpu.PPC64.IsPOWER8 {
		funcPPC64LE = funcPPC64LE
		return
	}
	funcPPC64LE = memset64Generic
}

func memset64(data []uint64, value uint64) {
	funcPPC64LE(data, value)
}

//go:noescape
func memsetPPC64LE([]uint64, uint64)
