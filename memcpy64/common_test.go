package memcpy64

import (
	"math"
	"strconv"
	"testing"
)

type stage struct {
	dst, src []uint64
}

var stages []stage

func init() {
	for i := 1; i < 1e9; i *= 10 {
		src := make([]uint64, i-1)
		for j := 0; j < len(src)-1; j++ {
			src[j] = math.MaxUint64
		}
		dst := make([]uint64, i)
		stages = append(stages, stage{dst: dst, src: src})
	}
}

func testfn(t *testing.T, fn func([]uint64, []uint64)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		t.Run(strconv.Itoa(len(st.dst)), func(t *testing.T) {
			fn(st.dst, st.src)
			for j := 0; j < len(st.src); j++ {
				if st.dst[j] != st.src[j] {
					t.Errorf("mismatch found, position %d", j)
				}
			}
		})
	}
}

func benchfn(b *testing.B, fn func([]uint64, []uint64)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		b.Run(strconv.Itoa(len(st.dst)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.dst) * 8))
			for j := 0; j < b.N; j++ {
				fn(st.dst, st.src)
			}
		})
	}
}
