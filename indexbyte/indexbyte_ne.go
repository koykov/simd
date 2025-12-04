package indexbyte

import "bytes"

func IndexNE(b []byte, x byte) (i int) {
	n := len(b)
	if n < 128 {
		return indexbyteneGeneric(b, x)
	}
	n64 := n - n%64
	if i = indexbytene(b[:n64], x); i >= 0 {
		return i
	}
	if i = indexbyteneGeneric(b[n64:], x); i >= 0 {
		return n64 + i
	}
	return -1
}

func IndexAtNE(b []byte, x byte, at int) (i int) {
	if at < 0 || at >= len(b) {
		return -1
	}
	if i = IndexNE(b[at:], x); i < 0 {
		return
	}
	return i + at
}

func indexbyteneGeneric(b []byte, x byte) int {
	var off int
	for {
		i := bytes.IndexByte(b[off:], x)
		if i < 0 {
			return -1
		}
		if i == 0 {
			return off
		}
		if i > 0 && b[off+i-1] != '\\' {
			return off + i
		}
		off += i + 1
	}
}

var _ = IndexAtNE
