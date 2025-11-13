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
		var sc int
		for j := off + i - 1; j >= 0 && b[j] == '\\'; j-- {
			sc++
		}
		if sc%2 == 0 {
			return i
		}
		off = i + 1
	}
}
