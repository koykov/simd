//go:build amd64

package hamming64

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestDistance(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, hammingGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, hammingSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, hammingAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { testfn(t, hammingAVX512) })
	}
}

func BenchmarkDistance(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, hammingGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, hammingSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, hammingAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		b.Run("avx512", func(b *testing.B) { benchfn(b, hammingAVX512) })
	}
}
