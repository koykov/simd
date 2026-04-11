package memequal

import (
	"math"
	"strconv"
	"testing"

	"golang.org/x/sys/cpu"
)

type bstage struct {
	a, b   []byte
	result bool
}

var bstages []bstage

func init() {
	for i := 1; i < 1e10; i *= 10 {
		a := make([]byte, i)
		for j := 0; j < len(a); j++ {
			a[j] = math.MaxUint8
		}
		b := append([]byte(nil), a...)
		bstages = append(bstages, bstage{a: a, b: b, result: true})
	}
}

func TestEqual(t *testing.T) {
	testfn := func(t *testing.T, fn func([]uint64, []uint64) bool) {
		for i := 0; i < len(bstages); i++ {
			st := bstages[i]
			t.Run(strconv.Itoa(len(st.a)), func(t *testing.T) {
				r := equal(st.a, st.b, fn)
				if r != st.result {
					t.Fail()
				}
			})
		}
	}

	t.Run("generic", func(t *testing.T) { testfn(t, memequal64Generic) })
	if cpu.X86.HasSSE2 {
		t.Run("sse2", func(t *testing.T) { testfn(t, memequalSSE2) })
	}
	if cpu.X86.HasAVX2 {
		t.Run("avx2", func(t *testing.T) { testfn(t, memequalAVX2) })
	}
	if cpu.X86.HasAVX512F {
		t.Run("avx512", func(t *testing.T) { testfn(t, memequalAVX512) })
	}
}

func BenchmarkEqual(b *testing.B) {
	benchfn := func(b *testing.B, fn func([]uint64, []uint64) bool) {
		for i := 0; i < len(bstages); i++ {
			st := bstages[i]
			b.Run(strconv.Itoa(len(st.a)), func(b *testing.B) {
				b.ReportAllocs()
				b.SetBytes(int64(len(st.a)))
				for j := 0; j < b.N; j++ {
					equal(st.a, st.b, fn)
				}
			})
		}
	}
	b.Run("generic", func(b *testing.B) { benchfn(b, memequal64Generic) })
	if cpu.X86.HasSSE2 {
		b.Run("sse2", func(b *testing.B) { benchfn(b, memequalSSE2) })
	}
	if cpu.X86.HasAVX2 {
		b.Run("avx2", func(b *testing.B) { benchfn(b, memequalAVX2) })
	}
	if cpu.X86.HasAVX512F {
		b.Run("avx512", func(b *testing.B) { benchfn(b, memequalAVX512) })
	}
}
