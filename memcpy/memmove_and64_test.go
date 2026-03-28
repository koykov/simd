package memcpy

import (
	"strconv"
	"testing"
	"unsafe"
)

func BenchmarkMemmove(b *testing.B) {
	b.Run("generic", func(b *testing.B) {
		for i := 0; i < len(stages); i++ {
			st := stages[i]
			if len(st.src) == 0 {
				continue
			}
			b.Run(strconv.Itoa(len(st.dst)), func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.dst) * 8))
				for j := 0; j < b.N; j++ {
					memmove(unsafe.Pointer(&st.dst[0]), unsafe.Pointer(&st.src), uintptr(len(st.src)))
				}
			})
		}
	})
	b.Run("avx512", func(b *testing.B) {
		for i := 0; i < len(stages); i++ {
			st := stages[i]
			if len(st.src) == 0 {
				continue
			}
			b.Run(strconv.Itoa(len(st.dst)), func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.dst) * 8))
				b.ResetTimer()
				for j := 0; j < b.N; j++ {
					memmoveAVX512(unsafe.Pointer(&st.dst[0]), unsafe.Pointer(&st.src), uintptr(len(st.src)))
				}
			})
		}
	})
}
