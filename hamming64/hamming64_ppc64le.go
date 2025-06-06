package hamming64

import "golang.org/x/sys/cpu"

var funcPPC64LE func([]uint64, []uint64) int

func init() {
	if cpu.PPC64.IsPOWER9 {
		funcPPC64LE = hammingPPC64LE
		return
	}
	funcPPC64LE = hammingGeneric
}

func hamming(a, b []uint64) int {
	return funcPPC64LE(a, b)
}

//go:noescape
func hammingPPC64LE(a, b []uint64) int
