package memcpy

import (
	"strconv"
	"testing"
	"unsafe"

	"golang.org/x/sys/cpu"
)

func BenchmarkMemmove(b *testing.B) {
	benchfn := func(b *testing.B, fn func(to, from unsafe.Pointer, n uintptr)) {
		for i := 0; i < len(stages); i++ {
			st := stages[i]
			if len(st.src) == 0 {
				continue
			}
			b.Run(strconv.Itoa(len(st.dst)), func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.dst) * 8))
				for j := 0; j < b.N; j++ {
					fn(unsafe.Pointer(&st.dst[0]), unsafe.Pointer(&st.src), uintptr(len(st.src)))
				}
			})
		}
	}
	b.Run("generic", func(b *testing.B) { benchfn(b, memmove) })
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, memmoveAVX512) })
	}
}
