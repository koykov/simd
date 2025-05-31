package memclr64

import "golang.org/x/sys/cpu"

var funcPPC64LE func([]uint64)

func init() {
	if cpu.PPC64.IsPOWER8 {
		funcPPC64LE = memclrPPC64LE
		return
	}
	funcPPC64LE = memclr64Generic
}

func memclr64(data []uint64) {
	funcPPC64LE(data)
}

//go:noescape
func memclrPPC64LE([]uint64)
