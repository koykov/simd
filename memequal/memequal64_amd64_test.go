package memequal

import (
	"math"
	"strconv"
	"testing"

	"golang.org/x/sys/cpu"
)

type stage struct {
	a, b   []uint64
	result bool
}

var stages []stage

func init() {
	for i := 1; i < 1e9; i *= 10 {
		b := make([]uint64, i)
		for j := 0; j < len(b); j++ {
			b[j] = math.MaxUint64
		}
		a := append([]uint64(nil), b...)
		stages = append(stages, stage{a: a, b: b, result: true})
	}
}

func TestCopy64(t *testing.T) {
	testfn := func(t *testing.T, fn func([]uint64, []uint64) bool) {
		for i := 0; i < len(stages); i++ {
			st := stages[i]
			t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
				_ = st.a[len(st.a)-1]
				r := fn(st.a, st.b)
				if r != st.result {
					t.Errorf("mismatch found: need %v got %v", st.result, r)
				}
			})
		}
	}
	t.Run("generic", func(t *testing.T) { testfn(t, memequal64Generic) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, memequalSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, memequalAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW {
		t.Run("avx512", func(t *testing.T) { testfn(t, memequalAVX512) })
	}
}

func BenchmarkCopy64(b *testing.B) {
	benchfn := func(b *testing.B, fn func([]uint64, []uint64) bool) {
		for i := 0; i < len(stages); i++ {
			st := stages[i]
			b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.a) * 8))
				for j := 0; j < b.N; j++ {
					fn(st.a, st.b)
				}
			})
		}
	}
	b.Run("generic", func(b *testing.B) { benchfn(b, memequal64Generic) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, memequalSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, memequalAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW {
		b.Run("avx512", func(b *testing.B) { benchfn(b, memequalAVX512) })
	}
}
