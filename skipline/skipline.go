package skipline

func SkipLine(b []byte) (i int) {
	n := len(b)
	if n < 64 {
		return skiplineGeneric(b)
	}
	n64 := n - n%64
	if i = skipline(b[:n64]); i >= 0 {
		return finalize(b, i)
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
	_ = b[len(b)-1]
	for i = 0; i < len(b); i++ {
		if b[i] == '\n' || b[i] == '\r' {
			return finalize(b, i)
		}
	}
	return -1
}

func finalize(b []byte, i int) int {
	if i < 0 {
		return i
	}
	_ = b[len(b)-1]
	for i < len(b) && (b[i] == '\n' || b[i] == '\r') {
		i++
	}
	return i
}
