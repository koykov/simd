package hamming

import (
	"math"
	"math/rand"
	"strconv"
	"testing"
)

type bstage struct {
	a, b []byte
	dist int
}

var bstages []bstage

func init() {
	for i := 10; i < 1e10; i *= 10 {
		a := make([]byte, i)
		b := make([]byte, i+rand.Intn(i/2)-rand.Intn(i/2))
		var d int
		for j := 0; j < i; j++ {
			a[j] = math.MaxUint8
			d += 8
		}
		bstages = append(bstages, bstage{a, b, d})
	}
}

func TestDistance(t *testing.T) {
	for i := 0; i < len(bstages); i++ {
		st := &bstages[i]
		t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
			d := Distance(st.a, st.b)
			if d != st.dist {
				t.Errorf("got %v, want %v", d, st.dist)
			}
		})
	}
}

func BenchmarkDistance(b *testing.B) {
	for i := 0; i < len(bstages); i++ {
		st := &bstages[i]
		b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
			b.SetBytes(int64(len(st.a) + len(st.b)))
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				Distance(st.a, st.b)
			}
		})
	}
}
