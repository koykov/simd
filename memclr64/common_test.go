package memclr64

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
		for j := 0; j < len(data); j++ {
			data[j] = math.MaxUint64
		}
		stages = append(stages, data)
	}
}

func testfn(t *testing.T, fn func([]uint64)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		t.Run(strconv.Itoa(len(st)), func(t *testing.T) {
			fn(st)
			var s uint64
			for j := 0; j < len(st); j++ {
				s += st[j]
			}
			if s != 0 {
				t.Errorf("expected 0, got %d", s)
			}
		})
	}
}

func benchfn(b *testing.B, fn func([]uint64)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		b.Run(strconv.Itoa(len(st)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st) * 8))
			for j := 0; j < b.N; j++ {
				fn(st)
			}
		})
	}
}
