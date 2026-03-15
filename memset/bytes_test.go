package memset

import (
	"math"
	"strconv"
	"testing"
)

type bstage []byte

var bstages []bstage

func init() {
	for i := 1; i < 1e10; i *= 10 {
		data := make([]byte, i)
		bstages = append(bstages, data)
	}
}

func TestMemset(t *testing.T) {
	for i := 0; i < len(bstages); i++ {
		st := bstages[i]
		t.Run(strconv.Itoa(len(st)), func(t *testing.T) {
			Memset(st, math.MaxUint8)
			for j := 0; j < len(st); j++ {
				if st[j] != math.MaxUint8 {
					t.Errorf("got %d, want %d", st[j], uint64(math.MaxUint8))
				}
			}
		})
	}
}

func BenchmarkDistance(b *testing.B) {
	for i := 0; i < len(bstages); i++ {
		st := bstages[i]
		b.Run(strconv.Itoa(len(st)), func(b *testing.B) {
			b.SetBytes(int64(len(st)))
			b.ReportAllocs()
			for j := 0; j < b.N; j++ {
				Memset(st, math.MaxUint8)
			}
		})
	}
}
