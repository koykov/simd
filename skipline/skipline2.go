package skipline

import "math"

// Index2 returns the index of last symbol of line (including NL/CR symbols).
func Index2(b []byte) (int, int) {
	n := len(b)
	if n < 64 {
		return skiplineGeneric2(b)
	}
	n64 := n - n%64
	if i := skipline(b[:n64]); i >= 0 {
		return i, finalize(b, i)
	}
	if i, j := skiplineGeneric2(b[n64:]); i >= 0 {
		return n64 + i, n64 + j
	}
	return -1, 0
}

func skiplineGeneric2(b []byte) (int, int) {
	if len(b) == 0 {
		return -1, 0
	}
	_, _ = b[len(b)-1], table[math.MaxUint8-1]
	for i := 0; i < len(b); i++ {
		if table[b[i]] {
			return i, finalize(b, i)
		}
	}
	return -1, 0
}

func finalize(b []byte, i int) int {
	if i < 0 {
		return i
	}
	if i < len(b)-1 && b[i] == '\r' && b[i+1] == '\n' {
		return i + 2
	}
	if i < len(b) && table[b[i]] {
		return i + 1
	}
	return i
}
