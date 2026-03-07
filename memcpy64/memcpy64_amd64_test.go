//go:build amd64

package memcpy64

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestMemcpy64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, memcpy64Generic) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, memcpySSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, memcpyAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfn(t, memcpyAVX512) })
	}
}

func BenchmarkMemcpy64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, memcpy64Generic) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, memcpySSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, memcpyAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, memcpyAVX512) })
	}
}
