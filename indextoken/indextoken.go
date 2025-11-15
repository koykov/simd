package indextoken

import "bytes"

func Index(b []byte) int {
	return indextokenAVX2(b)
}

func IndexAt(b []byte, at int) (i int) {
	if at < 0 || at >= len(b) {
		return -1
	}
	if i = Index(b[at:]); i < 0 {
		return
	}
	return i + at
}

func indextokenGeneric(b []byte) (i int) {
	return bytes.IndexAny(b, ".[]@")
}

var _ = IndexAt
