package popcnt64

import "golang.org/x/sys/cpu"

var ppc64lefn func([]uint64) uint64

func init() {
	if cpu.PPC64.IsPOWER8 {
		ppc64lefn = popcnt64PPC64LE
		return
	}
	ppc64lefn = popcnt64generic
}

func popcnt64(data []uint64) uint64 {
	return ppc64lefn(data)
}

func popcnt64PPC64LE([]uint64) uint64
