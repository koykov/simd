package bitwise64

func Or(a, b []uint64) {
	al, bl := len(a), len(b)
	mn := minI(al, bl)
	or(a[:mn], b[:mn])
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
