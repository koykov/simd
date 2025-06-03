package skipline

import "math"

// Index returns the index of last symbol of line (not including NL/CR symbols).
func Index(b []byte) (i int) {
	n := len(b)
	if n < 64 {
		return skiplineGeneric(b)
	}
	n64 := n - n%64
	if i = skipline(b[:n64]); i >= 0 {
		return i
	}
	if i = skiplineGeneric(b[n64:]); i >= 0 {
		return n64 + i
	}
	return -1
}

func skiplineGeneric(b []byte) (i int) {
	if len(b) == 0 {
		return -1
	}
	_, _ = b[len(b)-1], table[math.MaxUint8-1]
	for i = 0; i < len(b); i++ {
		if table[b[i]] {
			return i
		}
	}
	return -1
}
