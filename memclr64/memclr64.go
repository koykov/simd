package memclr64

// Clear clears array p.
func Clear(p []uint64) {
	memclr64(p)
}

func memclr64Generic(p []uint64) {
	_ = p[len(p)-1]
	for i := 0; i < len(p); i++ {
		p[i] = 0
	}
}
