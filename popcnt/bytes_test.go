package popcnt

import (
	"math/bits"
	"strconv"
	"testing"
)

type bstage struct {
	a []byte
	r uint64
}

var bstages []bstage

func init() {
	genericfn := func(p []byte) (r uint64) {
		for i := 0; i < len(p); i++ {
			r += uint64(bits.OnesCount8(p[i]))
		}
		return
	}
	var sample = []byte{0xFF, 0x00, 0x55, 0xAA}
	for i := 1; i < 1e10; i *= 10 {
		st := bstage{a: make([]byte, i)}
		for j := 0; j < i; j++ {
			st.a[j] = sample[j%len(sample)]
		}
		st.r = genericfn(st.a)
		bstages = append(bstages, st)
	}
}

func TestCount(t *testing.T) {
	for i := 0; i < len(bstages); i++ {
		st := bstages[i]
		t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
			r := Count(st.a)
			if r != st.r {
				t.Errorf("got %v, want %v", r, st.r)
			}
		})
	}
}

func BenchmarkCount(b *testing.B) {
	for i := 0; i < len(bstages); i++ {
		st := bstages[i]
		b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.a) * 8))
			for j := 0; j < b.N; j++ {
				Count(st.a)
			}
		})
	}
}
