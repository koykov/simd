package popcnt64

import (
	"strconv"
	"testing"
)

type popcnt64stage struct {
	a []uint64
	r uint64
}

var (
	popcnt64testInit  = []uint64{0xFFFFFFFFFFFFFFFF, 0x0000000000000000, 0x5555555555555555, 0xAAAAAAAAAAAAAAAA}
	popcnt64testSizes = []int{1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000}
)

func TestPopcnt64(t *testing.T) {
	for _, size := range popcnt64testSizes {
		stage := popcnt64stage{a: make([]uint64, size)}
		for i := 0; i < size; i++ {
			stage.a[i] = popcnt64testInit[i%len(popcnt64testInit)]
		}
		stage.r = countGeneric(stage.a)
		t.Run(strconv.Itoa(size), func(t *testing.T) {
			r := Count(stage.a)
			if r != stage.r {
				t.Errorf("Count(%d) = %d, want %d", size, r, stage.r)
			}
		})
	}
}

func BenchmarkPopcnt64(b *testing.B) {
	for _, size := range popcnt64testSizes {
		stage := popcnt64stage{a: make([]uint64, size)}
		b.Run(strconv.Itoa(size), func(b *testing.B) {
			b.ResetTimer()
			b.ReportAllocs()
			b.SetBytes(int64(size * 8))
			for i := 0; i < b.N; i++ {
				Count(stage.a)
			}
		})
	}
}
