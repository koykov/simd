//go:build amd64

package memset64

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestMemset64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, memset64Generic) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, memsetSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, memsetAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfn(t, memsetAVX512) })
	}
}

func BenchmarkMemset64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, memset64Generic) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, memsetSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, memsetAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, memsetAVX512) })
	}
}
