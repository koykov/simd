//go:build amd64

package memclr64

import (
	"testing"

	"golang.org/x/sys/cpu"
)

var testSizes = []int{1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000}

func TestMemclr64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, memclr64Generic) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, memclrSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, memclrAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfn(t, memclrAVX512) })
	}
}

func BenchmarkMemclr64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, memclr64Generic) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, memclrSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, memclrAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, memclrAVX512) })
	}
}
