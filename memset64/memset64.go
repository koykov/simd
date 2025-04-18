package memset64

// Memset fills array p with given value.
func Memset(p []uint64, value uint64) {
	memset64(p, value)
}

func memset64Generic(p []uint64, value uint64) {
	_ = p[len(p)-1]
	for i := 0; i < len(p); i++ {
		p[i] = value
	}
}
