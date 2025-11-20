package indexbyte

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestIndexNE(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, indexbyteneGeneric) })
	if cpu.ARM64.HasASIMD {
		t.Run("sse2", func(t *testing.T) { testfn(t, indexbyteneSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, indexbyteneAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { testfn(t, indexbyteneAVX512) })
	}
}

func TestIndexNE64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn64(t, indexbyteneGeneric) })
	if cpu.ARM64.HasASIMD {
		t.Run("sse2", func(t *testing.T) { testfn64(t, indexbyteneSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn64(t, indexbyteneAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { testfn64(t, indexbyteneAVX512) })
	}
}

func BenchmarkIndexNE(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, indexbyteneGeneric) })
	if cpu.ARM64.HasASIMD {
		b.Run("sse2", func(b *testing.B) { benchfn(b, indexbyteneSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, indexbyteneAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		b.Run("avx512", func(b *testing.B) { benchfn(b, indexbyteneAVX512) })
	}
}
