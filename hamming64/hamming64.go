package hamming64

import "math/bits"

func Distance(a, b []uint64) int {
	mn, mx := min(len(a), len(b)), max(len(a), len(b))
	dist := hamming(a[:mn], b[:mn])
	for i := mn; i < mx; i++ {
		dist += bits.OnesCount64(a[i] ^ b[i])
	}
	return dist
}

func hammingGeneric(a, b []uint64) (r int) {
	for i := 0; i < len(a); i++ {
		r += bits.OnesCount64(a[i] ^ b[i])
	}
	return r
}
