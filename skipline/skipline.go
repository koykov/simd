package skipline

func SkipLine(b []byte) (i int) {
	n := len(b)
	if n < 64 {
		return skiplineGeneric(b)
	}
	n64 := n - n%64
	if i = skipline(b[:n64]); i >= 0 {
		return
	}
	if i = skiplineGeneric(b[n64:]); i >= 0 {
		return n64 + i
	}
	return -1
}

func skiplineGeneric(b []byte) int {
	if len(b) == 0 {
		return -1
	}
	_ = b[len(b)-1]
	for i := 0; i < len(b); i++ {
		if b[i] == '\n' || b[i] == '\r' {
			return i
		}
	}
	return -1
}
