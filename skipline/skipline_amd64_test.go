//go:build amd64

package skipline

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestIndex(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, skiplineGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, skiplineSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, skiplineAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { testfn(t, skiplineAVX512) })
	}
}

func TestIndex2(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn2(t, skiplineGeneric) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn2(t, skiplineSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn2(t, skiplineAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { testfn2(t, skiplineAVX512) })
	}
}

func BenchmarkIndex(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, skiplineGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, skiplineSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, skiplineAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		b.Run("avx512", func(b *testing.B) { benchfn(b, skiplineAVX512) })
	}
}

func BenchmarkIndex2(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn2(b, skiplineGeneric) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn2(b, skiplineSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn2(b, skiplineAVX2) })
	}
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512BW && cpu.X86.HasAVX512VL {
		b.Run("avx512", func(b *testing.B) { benchfn2(b, skiplineAVX512) })
	}
}
