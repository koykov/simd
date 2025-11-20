package indexbyte

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestIndex(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, indexbyteGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, indexbyteSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, indexbyteAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { testfn(t, indexbyteAVX512) })
	}
}

func TestIndex64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn64(t, indexbyteGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn64(t, indexbyteSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn64(t, indexbyteAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { testfn64(t, indexbyteAVX512) })
	}
}

func BenchmarkIndex(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, indexbyteGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, indexbyteSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, indexbyteAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		b.Run("avx512", func(b *testing.B) { benchfn(b, indexbyteAVX512) })
	}
}
