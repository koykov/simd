package bitwise

import (
	"testing"

	"golang.org/x/sys/cpu"
)

var (
	stagesAnd  []stage
	bstagesAnd []bstage
)

func init() {
	for i := 10; i < 1e7; i *= 10 {
		a := make([]uint64, i)
		b := make([]uint64, i)
		var res int
		for j := 0; j < i; j++ {
			for k := uint64(0); k < 48; k++ {
				a[j] |= 1 << k
			}
			for k := uint64(16); k < 64; k++ {
				b[j] |= 1 << k
			}
			res += 32
		}
		stagesAnd = append(stagesAnd, stage{a, b, res})
	}
	for i := 10; i < 1e9; i *= 10 {
		a := make([]byte, i)
		b := make([]byte, i)
		var res int
		for j := 0; j < i; j++ {
			for k := byte(0); k < 6; k++ {
				a[j] |= 1 << k
			}
			for k := byte(2); k < 8; k++ {
				b[j] |= 1 << k
			}
			res += 4
		}
		bstagesAnd = append(bstagesAnd, bstage{a, b, res})
	}
}

func TestAnd64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, stagesAnd, andGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, stagesAnd, andSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, stagesAnd, andAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfn(t, stagesAnd, andAVX512) })
	}
}

func TestAnd(t *testing.T) {
	btestfn(t, bstagesAnd, And)
}

func BenchmarkAnd64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, stagesAnd, andGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, stagesAnd, andSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, stagesAnd, andAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, stagesAnd, andAVX512) })
	}
}

func BenchmarkAnd(b *testing.B) {
	bbenchfn(b, bstagesAnd, And)
}
