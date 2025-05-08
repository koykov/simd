package memclr64

import (
	"testing"
	"unsafe"
)

func TestUnsafe(t *testing.T) {
	type T struct {
		i int64
		u uint64
		f float64
		b bool
	}
	x := T{i: 1, u: 2, f: 3.0, b: true}
	ClearUnsafe(unsafe.Pointer(&x), int(unsafe.Sizeof(x)))
	if x.i != 0 || x.u != 0 || x.f != 0.0 || x.b {
		t.Fail()
	}
}
