//go:build arm64

package memclr64

import (
	"testing"

	"golang.org/x/sys/cpu"
)

var testSizes = []int{1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000}

func TestMemclr64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, memclr64Generic) })
	if cpu.ARM64.HasASIMD {
		t.Run("neon", func(t *testing.T) { testfn(t, memclrNEON) })
	}
}

func BenchmarkMemclr64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, memclr64Generic) })
	if cpu.ARM64.HasASIMD {
		b.Run("neon", func(b *testing.B) { benchfn(b, memclrNEON) })
	}
}
