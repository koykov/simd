package popcnt64

import (
	"strconv"
	"testing"
)

type stage struct {
	a []uint64
	r uint64
}

var stages []stage

func init() {
	var sample = []uint64{0xFFFFFFFFFFFFFFFF, 0x0000000000000000, 0x5555555555555555, 0xAAAAAAAAAAAAAAAA}
	for i := 1; i < 1e9; i *= 10 {
		st := stage{a: make([]uint64, i)}
		for j := 0; j < i; j++ {
			st.a[j] = sample[j%len(sample)]
		}
		st.r = countGeneric(st.a)
		stages = append(stages, st)
	}
}

func testfn(t *testing.T, fn func([]uint64) uint64) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
			r := fn(st.a)
			if r != st.r {
				t.Errorf("got %v, want %v", r, st.r)
			}
		})
	}
}

func benchfn(b *testing.B, fn func([]uint64) uint64) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.a) * 8))
			for j := 0; j < b.N; j++ {
				fn(st.a)
			}
		})
	}
}
