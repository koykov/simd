package indexbyte

import "bytes"

func Index(b []byte, x byte) (i int) {
	n := len(b)
	if n < 128 {
		return indexbyteGeneric(b, x)
	}
	n64 := n - n%64
	if i = indexbyte(b[:n64], x); i >= 0 {
		return i
	}
	if i = indexbyteGeneric(b[n64:], x); i >= 0 {
		return n64 + i
	}
	return -1
}

func IndexAt(b []byte, x byte, at int) (i int) {
	if at < 0 || at >= len(b) {
		return -1
	}
	if i = Index(b[at:], x); i < 0 {
		return
	}
	return i + at
}

func indexbyteGeneric(b []byte, x byte) (i int) {
	return bytes.IndexByte(b, x)
}

var _ = IndexAt
