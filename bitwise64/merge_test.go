package bitwise64

import (
	"strconv"
	"testing"
)

type stageMerge struct {
	a, b []uint64
	res  int
}

var stagesMerge []stageMerge

func init() {
	for i := 10; i < 1e7; i *= 10 {
		a := make([]uint64, i)
		b := make([]uint64, i)
		var res int
		for j := 0; j < i; j++ {
			for k := uint64(0); k < 32; k++ {
				a[j] |= 1 << k
			}
			for k := uint64(32); k < 64; k++ {
				b[j] |= 1 << k
			}
			res += 64
		}
		stagesMerge = append(stagesMerge, stageMerge{a, b, res})
	}
}

func testfnMerge(t *testing.T, fn func([]uint64, []uint64) int) {
	for i := 0; i < len(stagesMerge); i++ {
		st := &stagesMerge[i]
		t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
			d := fn(st.a, st.b)
			if d != st.res {
				t.Errorf("got %v, want %v", d, st.res)
			}
		})
	}
}

func benchfnMerge(b *testing.B, fn func([]uint64, []uint64) int) {
	for i := 0; i < len(stagesMerge); i++ {
		st := &stagesMerge[i]
		b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
			b.SetBytes(int64(len(st.a)) * 2 * 8)
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				fn(st.a, st.b)
			}
		})
	}
}
