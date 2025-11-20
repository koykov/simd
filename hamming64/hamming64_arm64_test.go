//go:build arm64

package hamming64

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestIndex(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, hammingGeneric) })
	if cpu.ARM64.HasASIMD {
		t.Run("neon", func(t *testing.T) { testfn(t, hammingNEON) })
	}
}

func TestIndex64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn64(t, hammingGeneric) })
	if cpu.ARM64.HasASIMD {
		t.Run("neon", func(t *testing.T) { testfn64(t, hammingNEON) })
	}
}

func BenchmarkIndex(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, hammingGeneric) })
	if cpu.ARM64.HasASIMD {
		b.Run("neon", func(b *testing.B) { benchfn(b, hammingNEON) })
	}
}
