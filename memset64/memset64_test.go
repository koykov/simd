package memset64

import (
	"math"
	"strconv"
	"testing"
)

var testSizes = []int{1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000}

func TestMemset64(t *testing.T) {
	for _, size := range testSizes {
		t.Run(strconv.Itoa(size), func(t *testing.T) {
			data := make([]uint64, size)
			Memset(data, math.MaxUint64)
			for i := 0; i < len(data); i++ {
				if data[i] != math.MaxUint64 {
					t.Errorf("got %d, want %d", data[i], uint64(math.MaxUint64))
				}
			}
		})
	}
}

func BenchmarkMemset64(b *testing.B) {
	for _, size := range testSizes {
		b.Run(strconv.Itoa(size), func(b *testing.B) {
			data := make([]uint64, size)
			b.SetBytes(int64(size) * 8)
			b.ReportAllocs()
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				Memset(data, math.MaxUint64)
			}
		})
	}
}
