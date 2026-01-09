package bitwise64

import (
	"math/bits"
	"strconv"
	"testing"

	"golang.org/x/sys/cpu"
)

type stageOr struct {
	a, b []uint64
	res  int
}

var stagesOr []stageOr

func init() {
	for i := 10; i < 1e7; i *= 10 {
		a := make([]uint64, i)
		b := make([]uint64, i)
		var res int
		for j := 0; j < i; j++ {
			for k := uint64(0); k < 32; k++ {
				a[j] |= 1 << k
			}
			for k := uint64(32); k < 64; k++ {
				b[j] |= 1 << k
			}
			res += 64
		}
		stagesOr = append(stagesOr, stageOr{a, b, res})
	}
}

func testfnOr(t *testing.T, fn func([]uint64, []uint64)) {
	for i := 0; i < len(stagesOr); i++ {
		st := &stagesOr[i]
		t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
			cpy := make([]uint64, len(st.a))
			copy(cpy, st.a)
			fn(cpy, st.b)
			var res int
			for j := 0; j < len(cpy); j++ {
				res += bits.OnesCount64(cpy[j])
			}
			if res != st.res {
				t.Errorf("got %v, want %v", res, st.res)
			}
		})
	}
}

func benchfnOr(b *testing.B, fn func([]uint64, []uint64)) {
	for i := 0; i < len(stagesOr); i++ {
		st := &stagesOr[i]
		b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
			b.SetBytes(int64(len(st.a)) * 2 * 8)
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				fn(st.a, st.b)
			}
		})
	}
}

func TestOr(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfnOr(t, orGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfnOr(t, orSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfnOr(t, orAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfnOr(t, orAVX512) })
	}
}

func BenchmarkOr(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfnOr(b, orGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfnOr(b, orSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfnOr(b, orAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfnOr(b, orAVX512) })
	}
}
