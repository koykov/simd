package memequal

import (
	"bytes"
	"unsafe"
)

func Equal64(a, b []uint64) bool {
	return memequal64(a, b)
}

func memequal64Generic(a, b []uint64) bool {
	type sh struct {
		p    uintptr
		l, c int
	}
	ash, bsh := *(*sh)(unsafe.Pointer(&a)), *(*sh)(unsafe.Pointer(&b))
	ash.l *= 8
	ash.c *= 8
	bsh.l *= 8
	bsh.c *= 8
	ab, bb := *(*[]byte)(unsafe.Pointer(&ash)), *(*[]byte)(unsafe.Pointer(&bsh))
	return bytes.Equal(ab, bb)
}
