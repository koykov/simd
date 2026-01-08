package bitwise64

import "errors"

func Merge(a, b []uint64) error {
	al, bl := len(a), len(b)
	if bl > al {
		return ErrMergeLTE
	}
	mn := minI(al, bl)
	merge(a[:mn], b[:mn])
	return nil
}

func mergeGeneric(a, b []uint64) {
	al, bl := len(a), len(b)
	mn := minI(al, bl)
	_, _ = a[al-1], b[bl-1]
	for i := 0; i < mn; i++ {
		a[i] = a[i] | b[i]
	}
}

func minI(a, b int) int {
	if a < b {
		return a
	}
	return b
}

var ErrMergeLTE = errors.New("length of second array must be less or equal to primary")
