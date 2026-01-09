package bitwise64

import "errors"

func Or(a, b []uint64) error {
	al, bl := len(a), len(b)
	if bl > al {
		return ErrOrLTE
	}
	mn := minI(al, bl)
	or(a[:mn], b[:mn])
	return nil
}

func orGeneric(a, b []uint64) {
	al, bl := len(a), len(b)
	mn := minI(al, bl)
	_, _ = a[al-1], b[bl-1]
	for i := 0; i < mn; i++ {
		a[i] |= b[i]
	}
}

func minI(a, b int) int {
	if a < b {
		return a
	}
	return b
}

var ErrOrLTE = errors.New("length of second array must be less or equal to primary")
