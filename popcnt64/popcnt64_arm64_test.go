//go:build arm64

package popcnt64

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestPopcnt64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, countGeneric) })
	if cpu.ARM64.HasASIMD {
		t.Run("neon", func(t *testing.T) { testfn(t, countNEON) })
	}
}

func BenchmarkPopcnt64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, countGeneric) })
	if cpu.ARM64.HasASIMD {
		b.Run("neon", func(b *testing.B) { benchfn(b, countNEON) })
	}
}
