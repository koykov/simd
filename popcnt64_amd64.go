package simdtk

import "golang.org/x/sys/cpu"

var amd64fn func([]uint64) uint64

func init() {
	if cpu.X86.HasBMI2 && cpu.X86.HasAVX512BW {
		amd64fn = popcnt64AVX512
		return
	}
	if cpu.X86.HasBMI2 && cpu.X86.HasAVX2 {
		amd64fn = popcnt64AVX2
		return
	}
	if cpu.X86.HasSSE2 {
		amd64fn = popcnt64SSE2
		return
	}
	amd64fn = popcnt64generic
}

func popcnt64(data []uint64) uint64 {
	return amd64fn(data)
}

func popcnt64SSE2([]uint64) uint64
func popcnt64AVX2([]uint64) uint64
func popcnt64AVX512([]uint64) uint64
