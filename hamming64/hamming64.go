package hamming64

import "math/bits"

// Distance returns the Hamming distance between two uint64 slices.
func Distance(a, b []uint64) (r int) {
	al, bl := len(a), len(b)
	mn := min(al, bl)
	r = hamming(a[:mn], b[:mn])
	if al == bl {
		return
	}
	rest := a[mn:]
	if bl > al {
		rest = b[mn:]
	}
	_ = rest[len(rest)-1]
	for i := 0; i < len(rest); i++ {
		r += bits.OnesCount64(rest[i])
	}
	return
}

func hammingGeneric(a, b []uint64) (r int) {
	al, bl := len(a), len(b)
	mn := min(al, bl)
	for i := 0; i < mn; i++ {
		r += bits.OnesCount64(a[i] ^ b[i])
	}
	rest := a[mn:]
	if bl > al {
		rest = b[mn:]
	}
	for i := 0; i < len(rest); i++ {
		r += bits.OnesCount64(rest[i])
	}
	return r
}
