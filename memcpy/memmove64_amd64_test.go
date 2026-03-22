package memcpy

import (
	"strconv"
	"testing"
	"unsafe"

	"golang.org/x/sys/cpu"
)

func mvtestfn(t *testing.T, fn func(dst, src unsafe.Pointer, n uintptr)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		t.Run(strconv.Itoa(len(st.dst)), func(t *testing.T) {
			fn(unsafe.Pointer(&st.dst[0]), unsafe.Pointer(&st.src[0]), uintptr(len(st.dst)))
			for j := 0; j < len(st.src); j++ {
				if st.dst[j] != st.src[j] {
					t.Errorf("mismatch found, position %d", j)
				}
			}
		})
	}
}

func mvbenchfn(b *testing.B, fn func(dst, src unsafe.Pointer, n uintptr)) {
	for i := 0; i < len(stages); i++ {
		st := stages[i]
		b.Run(strconv.Itoa(len(st.dst)), func(b *testing.B) {
			b.ReportAllocs()
			b.SetBytes(int64(len(st.dst) * 8))
			for j := 0; j < b.N; j++ {
				fn(unsafe.Pointer(&st.dst[0]), unsafe.Pointer(&st.src[0]), uintptr(len(st.dst)))
			}
		})
	}
}

func TestMove64(t *testing.T) {
	t.Run("generic", func(t *testing.T) { mvtestfn(t, memmove64Generic) })
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VL {
		t.Run("avx512", func(t *testing.T) { mvtestfn(t, memmoveAVX512) })
	}
}

func BenchmarkMove64(b *testing.B) {
	b.Run("generic", func(b *testing.B) { mvbenchfn(b, memmove64Generic) })
	if cpu.X86.HasAVX512F && cpu.X86.HasAVX512VL {
		b.Run("avx512", func(b *testing.B) { mvbenchfn(b, memmoveAVX512) })
	}
}
