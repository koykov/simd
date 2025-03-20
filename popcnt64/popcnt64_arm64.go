package popcnt64

import "golang.org/x/sys/cpu"

var arm64fn func([]uint64) uint64

func init() {
	if cpu.ARM64.HasASIMD {
		arm64fn = popcnt64NEON
		return
	}
	arm64fn = popcnt64generic
}

func popcnt64(data []uint64) uint64 {
	return arm64fn(data)
}

func popcnt64NEON([]uint64) uint64
