package memcpy

import (
	"strconv"
	"testing"
	"unsafe"

	"golang.org/x/sys/cpu"
)

func TestMemmove(t *testing.T) {
	testfn := func(t *testing.T, fn func(to, from unsafe.Pointer, n uintptr)) {
		for i := 0; i < len(stages); i++ {
			st := stages[i]
			if len(st.src) == 0 {
				continue
			}
			t.Run(strconv.Itoa(len(st.dst)), func(t *testing.T) {
				_ = st.dst[len(st.dst)-1]
				for j := 0; j < len(st.dst); j++ {
					st.dst[j] = 0
				}
				fn(unsafe.Pointer(&st.dst[0]), unsafe.Pointer(&st.src[0]), uintptr(len(st.src)))
				for j := 0; j < len(st.src); j++ {
					if st.dst[j] != st.src[j] {
						t.Errorf("mismatch found, position %d", j)
						return
					}
				}
			})
		}
	}
	t.Run("generic", func(t *testing.T) { testfn(t, memmove) })
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfn(t, memmoveAVX512) })
	}
}

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
					fn(unsafe.Pointer(&st.dst[0]), unsafe.Pointer(&st.src[0]), uintptr(len(st.src)))
				}
			})
		}
	}
	b.Run("generic", func(b *testing.B) { benchfn(b, memmove) })
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, memmoveAVX512) })
	}
}
