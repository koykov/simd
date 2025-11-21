package memset64

import (
	"math"
	"strconv"
	"testing"
)

type stage []uint64

var stages []stage

func init() {
	for i := 1; i < 1e9; i *= 10 {
		data := make([]uint64, i)
		stages = append(stages, data)
	}
}

func testfn(t *testing.T, fn func([]uint64, uint64)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		t.Run(strconv.Itoa(len(st)), func(t *testing.T) {
			fn(st, math.MaxUint64)
			for j := 0; j < len(st); j++ {
				if st[j] != math.MaxUint64 {
					t.Errorf("got %d, want %d", st[j], uint64(math.MaxUint64))
				}
			}
		})
	}
}

func benchfn(b *testing.B, fn func([]uint64, uint64)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		b.Run(strconv.Itoa(len(st)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st) * 8))
			for j := 0; j < b.N; j++ {
				fn(st, math.MaxUint64)
			}
		})
	}
}
