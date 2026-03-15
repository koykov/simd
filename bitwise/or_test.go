package bitwise

import (
	"testing"

	"golang.org/x/sys/cpu"
)

var (
	stagesOr  []stage
	bstagesOr []bstage
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
			for k := uint64(32); k < 64; k++ {
				b[j] |= 1 << k
			}
			res += 64
		}
		stagesOr = append(stagesOr, stage{a, b, res})
	}
	for i := 10; i < 1e9; i *= 10 {
		a := make([]byte, i)
		b := make([]byte, i)
		var res int
		for j := 0; j < i; j++ {
			for k := byte(0); k < 4; k++ {
				a[j] |= 1 << k
			}
			for k := byte(4); k < 8; k++ {
				b[j] |= 1 << k
			}
			res += 8
		}
		bstagesOr = append(bstagesOr, bstage{a, b, res})
	}
}

func TestOr64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, stagesOr, orGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, stagesOr, orSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, stagesOr, orAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfn(t, stagesOr, orAVX512) })
	}
}

func TestOr(t *testing.T) {
	btestfn(t, bstagesOr, Or)
}

func BenchmarkOr64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, stagesOr, orGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, stagesOr, orSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, stagesOr, orAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, stagesOr, orAVX512) })
	}
}

func BenchmarkOr(b *testing.B) {
	bbenchfn(b, bstagesOr, Or)
}
