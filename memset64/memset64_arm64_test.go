//go:build arm64

package memset64

import (
	"testing"

	"golang.org/x/sys/cpu"
)

var testSizes = []int{1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000}

func TestMemset64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, memset64Generic) })
	if cpu.ARM64.HasASIMD {
		t.Run("neon", func(t *testing.T) { testfn(t, memsetNEON) })
	}
}

func BenchmarkMemset64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, memset64Generic) })
	if cpu.ARM64.HasASIMD {
		b.Run("neon", func(b *testing.B) { benchfn(b, memsetNEON) })
	}
}
