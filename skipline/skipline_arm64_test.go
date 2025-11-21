//go:build arm64

package skipline

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestIndex(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, skiplineGeneric) })
	if cpu.ARM64.HasASIMD {
		t.Run("neon", func(t *testing.T) { testfn(t, skiplineNEON) })
	}
}

func TestIndex2(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn2(t, skiplineGeneric) })
	if cpu.ARM64.HasASIMD {
		t.Run("neon", func(t *testing.T) { testfn2(t, skiplineNEON) })
	}
}

func BenchmarkIndex(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, skiplineGeneric) })
	if cpu.ARM64.HasASIMD {
		b.Run("neon", func(b *testing.B) { benchfn(b, skiplineNEON) })
	}
}

func BenchmarkIndex2(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn2(b, skiplineGeneric) })
	if cpu.ARM64.HasASIMD {
		b.Run("neon", func(b *testing.B) { benchfn2(b, skiplineNEON) })
	}
}
