package popcnt64

import "math/bits"

// Count calculates population count in uint64 array.
func Count(data []uint64) uint64 {
	return count(data)
}

func countGeneric(data []uint64) (r uint64) {
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
