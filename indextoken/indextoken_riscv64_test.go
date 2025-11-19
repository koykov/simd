//go:build riscv64

package indextoken

import (
	"testing"

	"golang.org/x/sys/cpu"
)

func TestIndex(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn(t, indextokenGeneric) })
	if cpu.RISCV64.HasV {
		t.Run("neon", func(t *testing.T) { testfn(t, indextokenRISCV64) })
	}
}

func TestIndex64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { testfn64(t, indextokenGeneric) })
	if cpu.RISCV64.HasV {
		t.Run("neon", func(t *testing.T) { testfn64(t, indextokenRISCV64) })
	}
}

func BenchmarkIndex(b *testing.B) {
	b.Run("generic", func(b *testing.B) { benchfn(b, indextokenGeneric) })
	if cpu.RISCV64.HasV {
		b.Run("neon", func(b *testing.B) { benchfn(b, indextokenRISCV64) })
	}
}
