package simdtk

import "math/bits"

// Popcnt64 calculates population count in uint64 array.
func Popcnt64(data []uint64) uint64 {
	return popcnt64(data)
}

func popcnt64generic(data []uint64) (r uint64) {
	n := len(data)
	if n == 0 {
		return
	}
	_ = data[n-1]
	for i := 0; i < n; i++ {
		r += uint64(bits.OnesCount64(data[i]))
	}
	return
}
