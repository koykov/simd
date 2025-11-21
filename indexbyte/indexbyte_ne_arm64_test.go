//go:build arm64

package indexbyte

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestIndexNE(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, indexbyteneGeneric) })
	if cpu.ARM64.HasASIMD {
		t.Run("neon", func(t *testing.T) { testfn(t, indexbyteneNEON) })
	}
}

func TestIndexNE64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn64(t, indexbyteneGeneric) })
	if cpu.ARM64.HasASIMD {
		t.Run("neon", func(t *testing.T) { testfn64(t, indexbyteneNEON) })
	}
}

func BenchmarkIndexNE(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, indexbyteneGeneric) })
	if cpu.ARM64.HasASIMD {
		b.Run("neon", func(b *testing.B) { benchfn(b, indexbyteneNEON) })
	}
}
