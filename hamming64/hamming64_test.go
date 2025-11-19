package hamming64

import (
	"math"
	"strconv"
	"testing"
)

type stage struct {
	a, b []uint64
	dist int
}

var stages []stage

func init() {
	for i := 10; i < 1e7; i *= 10 {
		a := make([]uint64, i)
		b := make([]uint64, i)
		var d int
		for j := 0; j < i; j++ {
			a[j] = math.MaxUint64
			d += 64
		}
		stages = append(stages, stage{a, b, d})
	}
}

func TestDistance(t *testing.T) {
	for i := 0; i < len(stages); i++ {
		st := &stages[i]
		t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
			d := Distance(st.a, st.b)
			if d != st.dist {
				t.Errorf("got %v, want %v", d, st.dist)
			}
		})
	}
}

func BenchmarkDistance(b *testing.B) {
	for i := 0; i < len(stages); i++ {
		st := &stages[i]
		b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
			b.SetBytes(int64(len(st.a)) * 2 * 8)
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				Distance(st.a, st.b)
			}
		})
	}
}
