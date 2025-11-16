//go:build ppc64le

package indextoken

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestIndex(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, indextokenGeneric) })
	if cpu.PPC64.HasVMX && cpu.PPC64.HasVSX {
		t.Run("neon", func(t *testing.T) { testfn(t, indextokenPPC64LE) })
	}
}

func TestIndex64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn64(t, indextokenGeneric) })
	if cpu.PPC64.HasVMX && cpu.PPC64.HasVSX {
		t.Run("neon", func(t *testing.T) { testfn64(t, indextokenPPC64LE) })
	}
}

func BenchmarkIndex(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, indextokenGeneric) })
	if cpu.PPC64.HasVMX && cpu.PPC64.HasVSX {
		b.Run("neon", func(b *testing.B) { benchfn(b, indextokenPPC64LE) })
	}
}
