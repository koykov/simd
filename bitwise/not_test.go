package bitwise

import (
	"math/bits"
	"strconv"
	"testing"

	"golang.org/x/sys/cpu"
)

var (
	stagesNot  []stage
	bstagesNot []bstage
)

func init() {
	for i := 10; i < 1e7; i *= 10 {
		a := make([]uint64, i)
		b := make([]uint64, i)
		var res int
		for j := 0; j < i; j++ {
			for k := uint64(0); k < 32; k++ {
				a[j] |= 1 << k
			}
			res += 32
		}
		stagesNot = append(stagesNot, stage{a, b, res})
	}
	for i := 10; i < 1e9; i *= 10 {
		a := make([]byte, i)
		b := make([]byte, i)
		var res int
		for j := 0; j < i; j++ {
			for k := byte(0); k < 4; k++ {
				a[j] |= 1 << k
			}
			res += 4
		}
		bstagesNot = append(bstagesNot, bstage{a, b, res})
	}
}

func TestNot(t *testing.T) {
	testfnNot := func(t *testing.T, stages []stage, fn func([]uint64)) {
		for i := 0; i < len(stages); i++ {
			st := &stages[i]
			t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
				cpy := make([]uint64, len(st.a))
				copy(cpy, st.a)
				fn(cpy)
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
	t.Run("generic", func(t *testing.T) { testfnNot(t, stagesNot, notGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfnNot(t, stagesNot, notSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfnNot(t, stagesNot, notAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfnNot(t, stagesNot, notAVX512) })
	}
}

func TestNotBytes(t *testing.T) {
	testfnNotBytes := func(t *testing.T, stages []bstage, fn func([]byte)) {
		for i := 0; i < len(stages); i++ {
			st := &stages[i]
			t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
				cpy := make([]byte, len(st.a))
				copy(cpy, st.a)
				fn(cpy)
				var res int
				for j := 0; j < len(cpy); j++ {
					res += bits.OnesCount8(cpy[j])
				}
				if res != st.res {
					t.Errorf("got %v, want %v", res, st.res)
				}
			})
		}
	}
	testfnNotBytes(t, bstagesNot, Not)
}

func BenchmarkNot(b *testing.B) {
	benchfnNot := func(b *testing.B, stages []stage, fn func([]uint64)) {
		for i := 0; i < len(stages); i++ {
			st := &stages[i]
			b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
				b.SetBytes(int64(len(st.a)) * 8)
				b.ReportAllocs()
				for i := 0; i < b.N; i++ {
					fn(st.a)
				}
			})
		}
	}
	b.Run("generic", func(b *testing.B) { benchfnNot(b, stagesNot, notGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfnNot(b, stagesNot, notSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfnNot(b, stagesNot, notAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfnNot(b, stagesNot, notAVX512) })
	}
}

func BenchmarkNotBytes(b *testing.B) {
	benchfnNotBytes := func(b *testing.B, stages []bstage, fn func([]byte)) {
		for i := 0; i < len(stages); i++ {
			st := &stages[i]
			b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
				b.SetBytes(int64(len(st.a)))
				b.ReportAllocs()
				for i := 0; i < b.N; i++ {
					fn(st.a)
				}
			})
		}
	}
	benchfnNotBytes(b, bstagesNot, Not)
}
