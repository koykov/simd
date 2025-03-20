package simdtk

import "golang.org/x/sys/cpu"

var riscv64lefn func([]uint64) uint64

func init() {
	if cpu.RISCV64.HasV {
		riscv64lefn = popcnt64RISCV64
		return
	}
	riscv64lefn = popcnt64generic
}

func popcnt64(data []uint64) uint64 {
	return riscv64lefn(data)
}

func popcnt64RISCV64([]uint64) uint64
