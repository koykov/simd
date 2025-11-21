//go:build amd64

package popcnt64

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestPopcnt64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, countGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, countSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, countAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfn(t, countAVX512) })
	}
}

func BenchmarkPopcnt64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, countGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, countSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, countAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, countAVX512) })
	}
}
